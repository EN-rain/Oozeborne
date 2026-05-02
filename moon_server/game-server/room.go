package main

import (
	"encoding/json"
	"log"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

type Room struct {
	RoomID    string
	RoomCode  string
	Seed      int64
	HostID    string
	State     MatchState
	WaveNum   int
	WaveTimer float64
	Players   map[string]*Player
	Mobs      map[string]*MobState
	ReadySet  map[string]bool
	mu        sync.RWMutex
	tickStop  chan struct{}
}

type RoomManager struct {
	rooms map[string]*Room
	mu    sync.RWMutex
}

func NewRoomManager() *RoomManager {
	return &RoomManager{rooms: make(map[string]*Room)}
}

func (rm *RoomManager) GetOrCreate(roomID, roomCode string) *Room {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	if r, ok := rm.rooms[roomID]; ok {
		return r
	}
	r := &Room{
		RoomID:   roomID,
		RoomCode: roomCode,
		Seed:     time.Now().UnixNano(),
		State:    StateLobby,
		Players:  make(map[string]*Player),
		Mobs:     make(map[string]*MobState),
		ReadySet: make(map[string]bool),
		tickStop: make(chan struct{}),
	}
	rm.rooms[roomID] = r
	go r.tickLoop()
	return r
}

func (r *Room) SpawnMob(mobType string) {
	configMu.RLock()
	config, ok := mobConfigs[mobType]
	configMu.RUnlock()

	hp := 100
	if ok {
		hp = config.Health
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	mobID := uuid.New().String()
	r.Mobs[mobID] = &MobState{
		MobID:   mobID,
		MobType: mobType,
		PosX:    WorldBoundsX * 0.8,
		PosY:    WorldBoundsY * 0.5,
		HP:      hp,
	}
	log.Printf("[ROOM %s] Spawned mob %s (%s) with %d HP", r.RoomID, mobID, mobType, hp)
}

func (r *Room) tickLoop() {
	ticker := time.NewTicker(TickInterval)
	statsTicker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()
	defer statsTicker.Stop()
	for {
		select {
		case <-r.tickStop:
			return
		case <-ticker.C:
			r.tick()
		case <-statsTicker.C:
			r.syncStats()
		}
	}
}

func (r *Room) syncStats() {
	if redisClient == nil {
		return
	}
	r.mu.RLock()
	defer r.mu.RUnlock()

	type PStats struct {
		ID    string `json:"id"`
		Name  string `json:"name"`
		Lvl   int    `json:"lvl"`
		Kills int    `json:"kills"`
		Dmg   int    `json:"dmg"`
		Gold  int    `json:"gold"`
	}
	stats := struct {
		RoomID     string   `json:"room_id"`
		Wave       int      `json:"wave"`
		Difficulty string   `json:"difficulty"`
		Players    []PStats `json:"players"`
	}{
		RoomID:     r.RoomID,
		Wave:       r.WaveNum,
		Difficulty: "Normal",
		Players:    []PStats{},
	}

	for _, p := range r.Players {
		stats.Players = append(stats.Players, PStats{
			ID: p.UserID, Name: "Player", Lvl: p.Build.Level,
			Kills: p.Vitals.Kills, Dmg: p.Vitals.DmgDealt, Gold: p.Vitals.Gold,
		})
	}

	data, _ := json.Marshal(stats)
	redisClient.Set(ctx, "room_stats:"+r.RoomID, data, 10*time.Second)
}

func (r *Room) tick() {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.State != StateInWave {
		return
	}

	for _, p := range r.Players {
		p.mu.Lock()
		if len(p.InputQueue) > 0 {
			input := p.InputQueue[0]
			p.InputQueue = p.InputQueue[1:]

			p.LastPos = p.Pos
			applyInput(r, p, input)
			handleAttack(r, p, input)

			maxSpeed := MaxMoveSpeed
			if p.Vitals.Speed > 0 {
				maxSpeed = (p.Vitals.Speed / float64(TickRate)) * 1.2
			}
			dx := p.Pos.X - p.LastPos.X
			dy := p.Pos.Y - p.LastPos.Y
			if math.Sqrt(dx*dx+dy*dy) > maxSpeed {
				p.Pos = p.LastPos
				log.Printf("[ANTICHEAT] Player %s speed violation — rolled back", p.UserID)
			}
			p.LastInputTime = time.Now()
		}
		if time.Since(p.LastInputTime).Seconds() > AFKTimeoutSec {
			p.Vitals.IsAFK = true
		}
		p.mu.Unlock()
	}

	for _, m := range r.Mobs {
		configMu.RLock()
		config, ok := mobConfigs[m.MobType]
		configMu.RUnlock()

		speed := 1.0
		damage := 10
		if ok {
			speed = config.Speed / float64(TickRate)
			damage = config.Damage
		}

		var nearest *Player
		minDist := 999999.0
		for _, p := range r.Players {
			dx := p.Pos.X - m.PosX
			dy := p.Pos.Y - m.PosY
			dist := math.Sqrt(dx*dx+dy*dy)
			if dist < minDist {
				minDist = dist
				nearest = p
			}
		}

		stopDist := 5.0
		if nearest != nil {
			if minDist > stopDist {
				angle := math.Atan2(nearest.Pos.Y-m.PosY, nearest.Pos.X-m.PosX)
				m.PosX += math.Cos(angle) * speed
				m.PosY += math.Sin(angle) * speed
			} else {
				if time.Since(m.LastAttackTime).Milliseconds() > 1000 && nearest.Vitals.HP > 0 {
					m.LastAttackTime = time.Now()
					nearest.Vitals.HP -= damage
					if nearest.Vitals.HP <= 0 {
						nearest.Vitals.HP = 0
						nearest.Vitals.DeathState = DeathStateDowned
					}
					hitMsg, _ := json.Marshal(map[string]any{
						"op": OP_PLAYER_HIT, "target_id": nearest.UserID, "damage": damage,
					})
					r.broadcast(hitMsg)
				}
			}
		}
	}

	r.broadcastState()
}

func (r *Room) broadcastState() {
	type playerSnap struct {
		UserID string       `json:"user_id"`
		PosX   float64      `json:"pos_x"`
		PosY   float64      `json:"pos_y"`
		Vitals PlayerVitals `json:"vitals"`
		Build  PlayerBuild  `json:"build"`
	}

	players := make([]playerSnap, 0, len(r.Players))
	for _, p := range r.Players {
		players = append(players, playerSnap{
			UserID: p.UserID, PosX: p.Pos.X, PosY: p.Pos.Y,
			Vitals: p.Vitals, Build: p.Build,
		})
	}
	mobs := make([]*MobState, 0, len(r.Mobs))
	for _, m := range r.Mobs {
		mobs = append(mobs, m)
	}
	msg, _ := json.Marshal(map[string]any{
		"op": OP_STATE, "wave_num": r.WaveNum,
		"wave_timer": r.WaveTimer, "players": players, "mobs": mobs,
	})
	r.broadcast(msg)
}

func (r *Room) broadcast(msg []byte) {
	for _, p := range r.Players {
		p.mu.Lock()
		_ = p.Conn.SetWriteDeadline(time.Now().Add(WriteTimeout))
		_ = p.Conn.WriteMessage(websocket.TextMessage, msg)
		p.mu.Unlock()
	}
}
