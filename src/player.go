package main

import "github.com/gorilla/websocket"

type Player struct {
	ID       string          `json:"id"`
	Name     string          `json:"name"`
	Word     string          `json:"word"`
	PrevWord string          `json:"prevWord"`
	IsReady  bool            `json:"isReady"`
	Conn     *websocket.Conn `json:"-"`
}
