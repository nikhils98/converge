package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

type PlayerConn struct {
	PlayerID string `json:"playerId"`
	GameID   string `json:"gameId"`
}

type NotifyGame struct {
	Game
	Id string `json:"id"`
}

var (
	GameMap       = make(map[string]*Game)
	PlayerConnMap = make(map[*websocket.Conn]PlayerConn)
	upgrader      = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
)

func main() {
	router := gin.Default()

	config := cors.DefaultConfig()
	config.AllowOriginFunc = func(origin string) bool {
		return strings.HasPrefix(origin, "http://localhost") || origin == "https://converge-dg4.pages.dev"
	}
	router.Use(cors.New(config))

	router.GET("/ws", handleWebSocket)
	router.GET("/health", func(c *gin.Context) { c.String(http.StatusOK, "ok") })
	router.Run(":8080")
}

func handleWebSocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upgrade to WebSocket"})
		return
	}

	defer conn.Close()

	conn.SetCloseHandler(func(code int, text string) error {
		return handlePlayerConnectionLost(conn)
	})

	/**
	* The server sends a ping message every 30 seconds,
	* and it expects to receive a pong response within 60 seconds.
	* If the pong isn't received within the deadline, the connection is closed.
	 */
	conn.SetPongHandler(func(appData string) error {
		return conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	})

	conn.SetReadDeadline(time.Now().Add(60 * time.Second))

	go func() {
		for {
			time.Sleep(30 * time.Second)
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}()

	for {
		var req Req

		err = conn.ReadJSON(&req)
		if err != nil {
			if err.Error() == "websocket: close 1006 (abnormal closure): unexpected EOF" {
				handlePlayerConnectionLost(conn)
				return
			}

			conn.WriteJSON(gin.H{"error": "Invalid request"})

			return
		}

		switch req.Action {
		case JoinGame:
			var data JoinGameReq
			if err := json.Unmarshal(req.Data, &data); err != nil {
				fmt.Println("Error unmarshalling JoinGameReq JSON:", err)
				return
			}
			handleJoinGame(data, conn)
		case EnterWord:
			var data EnterWordReq
			if err := json.Unmarshal(req.Data, &data); err != nil {
				fmt.Println("Error unmarshalling EnterWordReq JSON:", err)
				return
			}
			handleEnterWord(data, conn)
		case PlayerReady:
			var data PlayerReadyReq
			if err := json.Unmarshal(req.Data, &data); err != nil {
				fmt.Println("Error unmarshalling EnterWordReq JSON:", err)
				return
			}
			handlePlayerReady(data, conn)
		case Restart:
			handleRestart(conn)
		}
	}
}

func handlePlayerConnectionLost(conn *websocket.Conn) error {
	var playerConn = PlayerConnMap[conn]
	var game = GameMap[playerConn.GameID]

	game.RemovePlayerByID(playerConn.PlayerID)

	if len(game.Players) > 0 {
		if len(game.Players) == 1 {
			game.IsRunning = false
			game.IsWon = false
			game.Round = 1
		}
		notify(NotifyGame{Game: *game, Id: playerConn.GameID})
	} else {
		delete(GameMap, playerConn.GameID)
	}

	delete(PlayerConnMap, conn)

	return nil
}

func handleJoinGame(data JoinGameReq, conn *websocket.Conn) {
	var player = Player{ID: generateRandomID(), Name: data.PlayerName, Word: "", PrevWord: "", IsReady: false, Conn: conn}

	if data.GameID == "" {
		data.GameID = generateRandomID()
		GameMap[data.GameID] = &Game{Round: 1, IsRunning: false, IsWon: false, Players: []*Player{&player}}
	} else if game, exists := GameMap[data.GameID]; exists {
		if len(game.Players) == 2 {
			conn.WriteJSON(gin.H{"error": "Only 2 players can join"})
			return
		}

		game.Players = append(game.Players, &player)
	} else {
		conn.WriteJSON(gin.H{"error": "Game ID is invalid"})
		return
	}

	PlayerConnMap[conn] = PlayerConn{PlayerID: player.ID, GameID: data.GameID}
	notify(NotifyGame{Game: *GameMap[data.GameID], Id: data.GameID})
}

func handleEnterWord(data EnterWordReq, conn *websocket.Conn) {
	var playerConn = PlayerConnMap[conn]
	var players = GameMap[playerConn.GameID].Players

	var allPlayersSubmitted = true
	var doWordsMatch = true

	for i, player := range players {
		if player.ID == playerConn.PlayerID {
			player.Word = data.Word
		}
		if player.Word == "" {
			allPlayersSubmitted = false
		} else if i > 0 && player.Word != players[i-1].Word {
			doWordsMatch = false
		}
	}

	if allPlayersSubmitted {
		if doWordsMatch {
			GameMap[playerConn.GameID].IsWon = true
		} else {
			GameMap[playerConn.GameID].Round++
			for _, player := range players {
				player.IsReady = false
				player.PrevWord = player.Word
				player.Word = ""
			}
		}
		GameMap[playerConn.GameID].IsRunning = false
	}

	notify(NotifyGame{Game: *GameMap[playerConn.GameID], Id: playerConn.GameID})
}

func handlePlayerReady(data PlayerReadyReq, conn *websocket.Conn) {
	var playerConn = PlayerConnMap[conn]
	var allPlayersReady = true

	for _, player := range GameMap[playerConn.GameID].Players {
		if player.ID == playerConn.PlayerID {
			player.IsReady = data.IsReady
		}

		if !player.IsReady {
			allPlayersReady = false
		}
	}

	if allPlayersReady {
		GameMap[playerConn.GameID].IsRunning = true
	}

	notify(NotifyGame{Game: *GameMap[playerConn.GameID], Id: playerConn.GameID})
}

func handleRestart(conn *websocket.Conn) {
	var playerConn = PlayerConnMap[conn]
	var game = GameMap[playerConn.GameID]

	game.IsWon = false
	game.IsRunning = false
	game.Round = 1
	for _, player := range game.Players {
		player.IsReady = false
		player.PrevWord = ""
		player.Word = ""
	}

	notify(NotifyGame{Game: *game, Id: playerConn.GameID})
}

func notify(game NotifyGame) {
	for _, player := range game.Players {
		player.Conn.WriteJSON(gin.H{"game": game, "playerId": player.ID})
	}
}
