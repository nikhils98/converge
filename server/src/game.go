package main

type Game struct {
	Round     int       `json:"round"`
	IsRunning bool      `json:"isRunning"`
	IsWon     bool      `json:"isWon"`
	Players   []*Player `json:"players"`
}

func (g *Game) RemovePlayerByID(playerID string) {
	for i, player := range g.Players {
		if player.ID == playerID {
			g.Players = append(g.Players[:i], g.Players[i+1:]...)
			return
		}
	}
}
