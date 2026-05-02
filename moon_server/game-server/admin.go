package main

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

func listenAdminCommands() {
	pubsub := redisClient.Subscribe(ctx, "admin_commands")
	defer pubsub.Close()

	for {
		msg, err := pubsub.ReceiveMessage(ctx)
		if err != nil {
			log.Printf("Redis pubsub error: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}

		var cmd struct {
			Cmd     string `json:"cmd"`
			RoomID  string `json:"room_id"`
			UserID  string `json:"user_id"`
			MobType string `json:"mob_type"`
			Count   int    `json:"count"`
			Value   any    `json:"value"`
		}
		if err := json.Unmarshal([]byte(msg.Payload), &cmd); err != nil {
			continue
		}

		log.Printf("[ADMIN] Received command: %s for Room: %s", cmd.Cmd, cmd.RoomID)

		switch cmd.Cmd {
		case "kill_room":
			room := roomManager.rooms[cmd.RoomID]
			if room != nil {
				room.mu.Lock()
				close(room.tickStop)
				for _, p := range room.Players {
					p.Conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, "Room terminated by admin"))
					p.Conn.Close()
				}
				room.mu.Unlock()
				roomManager.mu.Lock()
				delete(roomManager.rooms, cmd.RoomID)
				roomManager.mu.Unlock()
			}
		case "spawn_mob":
			room := roomManager.rooms[cmd.RoomID]
			if room != nil {
				mobType := cmd.MobType
				if mobType == "" {
					mobType = "slime"
				}
				count := cmd.Count
				if count <= 0 {
					count = 1
				}
				for i := 0; i < count; i++ {
					room.SpawnMob(mobType)
				}
			}
		}
	}
}
