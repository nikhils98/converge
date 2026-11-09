package main

import "encoding/json"

type ActionType string

const (
	JoinGame    ActionType = "JoinGame"
	EnterWord   ActionType = "EnterWord"
	PlayerReady ActionType = "PlayerReady"
	Restart     ActionType = "Restart"
)

type Req struct {
	Action ActionType      `json:"action"`
	Data   json.RawMessage `json:"data"`
}

type JoinGameReq struct {
	GameID     string `json:"gameId"`
	PlayerName string `json:"playerName"`
}

type EnterWordReq struct {
	Word string `json:"word"`
}

type PlayerReadyReq struct {
	IsReady bool `json:"isReady"`
}
