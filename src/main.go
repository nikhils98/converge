package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/gin-gonic/autotls"
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
	router.GET("/ws", handleWebSocket)
	router.Run(":8080")
	fmt.Print(autotls.Run(router, "converge.dijkstrai.com"))
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

	for {
		var req Req

		err = conn.ReadJSON(&req)
		if err != nil {
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
		if len(game.Players) == 4 {
			conn.WriteJSON(gin.H{"error": "Only 4 players can join"})
			return
		}

		game.Players = append(game.Players, &player)
	} else {
		conn.WriteJSON(gin.H{"error": "Game ID does not exist"})
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
