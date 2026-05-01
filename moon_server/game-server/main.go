package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

var (
	ctx         = context.Background()
	redisClient *redis.Client
	
	// Game Config (Live Tuning)
	configMu     sync.RWMutex
	mobConfigs   = make(map[string]MobConfig)
	itemConfigs  = make(map[string]ItemConfig)
	classConfigs = make(map[string]ClassConfig)
)

type MobConfig struct {
	MobType    string  `json:"mob_type"`
	Health     int     `json:"health"`
	Speed      float64 `json:"speed"`
	Damage     int     `json:"damage"`
	XPReward   int     `json:"xp_reward"`
	GoldReward int     `json:"gold_reward"`
	Category   string  `json:"category"`
}

type ItemConfig struct {
	ItemID      string  `json:"item_id"`
	DisplayName string  `json:"display_name"`
	Description string  `json:"description"`
	Price       int     `json:"price"`
	StatType    string  `json:"stat_type"`
	StatValue   float64 `json:"stat_value"`
	InstantHeal int     `json:"instant_heal"`
	Duration    int     `json:"duration"`
	Category    string  `json:"category"`
}

type Skill struct {
	Name string `json:"name"`
	Desc string `json:"desc"`
}

type ClassConfig struct {
	ClassID          string  `json:"class_id"`
	DisplayName      string  `json:"display_name"`
	BaseMaxHealth    int     `json:"base_max_health"`
	BaseSpeed        float64 `json:"base_speed"`
	BaseAttackDamage int     `json:"base_attack_damage"`
	BaseCritChance   float64 `json:"base_crit_chance"`
	BaseMaxMana      int     `json:"base_max_mana"`
	HealthPerLevel   int     `json:"health_per_level"`
	DamagePerLevel   int     `json:"damage_per_level"`
	Skills           []Skill `json:"skills"`
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants (matching lobby.lua parity)
// ─────────────────────────────────────────────────────────────────────────────

const (
	TickRate           = 20
	TickInterval       = time.Second / TickRate
	WorldBoundsX       = 800.0
	WorldBoundsY       = 600.0
	PlayerRadius       = 6.0
	AttackCooldownMs   = 500
	AttackRange        = 60.0
	InputQueueMax      = 10
	DisconnectGraceSec = 15
	AFKTimeoutSec      = 120

	// Security
	MaxMessageBytes    = 4 * 1024        // 4KB max per WS message
	MaxPlayersPerRoom  = 4
	MaxConnectionsTotal = 200            // global WS connection cap
	MaxMoveSpeed       = 4.0            // max pixels/tick — reject speed hacks
	MaxRoomIDLen       = 64
	MaxUserIDLen       = 64
	WSHandshakeTimeout = 5 * time.Second
	WriteTimeout       = 10 * time.Second
)

// ─────────────────────────────────────────────────────────────────────────────
// OpCodes
// ─────────────────────────────────────────────────────────────────────────────

const (
	OP_INPUT          = 1
	OP_START_GAME     = 5
	OP_PLAYER_READY   = 10
	OP_UPGRADE_SELECT = 11
	OP_VOTE_KICK      = 12
	OP_EMOTE          = 13

	OP_MESSAGE             = 0
	OP_STATE               = 2
	OP_PLAYER_JOIN         = 3
	OP_PLAYER_LEAVE        = 4
	OP_SYNC_ALL            = 6
	OP_WAVE_START          = 7
	OP_WAVE_END            = 8
	OP_MOB_SPAWN           = 14
	OP_MOB_DIE             = 15
	OP_PLAYER_RECONNECTING = 16
	OP_VOTE_STATUS         = 17
	OP_GAME_OVER           = 18
	OP_BUY_ITEM            = 19
	OP_PLAYER_HIT          = 20
	OP_LEVEL_UP            = 21
)

// ─────────────────────────────────────────────────────────────────────────────
// Match State Machine
// ─────────────────────────────────────────────────────────────────────────────

type MatchState int

const (
	StateLobby        MatchState = iota
	StatePreWave
	StateInWave
	StateUpgradePhase
	StateResults
)

type DeathState string

const (
	DeathStateAlive  DeathState = "ALIVE"
	DeathStateDowned DeathState = "DOWNED"
	DeathStateDead   DeathState = "DEAD"
)

// ─────────────────────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────────────────────

type Vec2 struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

type PlayerInput struct {
	Seq         int     `json:"seq"`
	MoveX       float64 `json:"move_x"`
	MoveY       float64 `json:"move_y"`
	AttackFlags int     `json:"attack_flags"`
	Rotation    float64 `json:"rotation"`
}

type PlayerVitals struct {
	HP         int        `json:"hp"`
	MaxHP        int        `json:"max_hp"`
	Mana         int        `json:"mana"`
	MaxMana      int        `json:"max_mana"`
	AttackDamage int        `json:"attack_damage"`
	Speed        float64    `json:"speed"`
	DeathState   DeathState `json:"death_state"`
	Kills      int        `json:"kills"`
	DmgDealt   int        `json:"dmg_dealt"`
	Gold       int        `json:"gold"`
	XP         int        `json:"xp"`
	PingRTT    int        `json:"ping_rtt_ms"`
	IsAFK      bool       `json:"is_afk"`
}

type PlayerBuild struct {
	Level int      `json:"level"`
	Items []string `json:"items"`
}

type Player struct {
	UserID           string
	ClassID          string
	Conn             *websocket.Conn
	Pos              Vec2
	LastPos          Vec2 // for speed-hack detection
	Vitals           PlayerVitals
	Build            PlayerBuild
	InputQueue       []PlayerInput
	LastInputTime    time.Time
	LastAttackTime   time.Time
	LastSeen         time.Time
	PingSentAt       time.Time
	LastSeqSeen      int
	mu               sync.Mutex
}

type MobState struct {
	MobID   string  `json:"mob_id"`
	MobType string  `json:"mob_type"`
	PosX    float64 `json:"pos_x"`
	PosY           float64   `json:"pos_y"`
	HP             int       `json:"hp"`
	LastAttackTime time.Time `json:"-"`
}

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

// ─────────────────────────────────────────────────────────────────────────────
// Global connection counter (DoS protection)
// ─────────────────────────────────────────────────────────────────────────────

var (
	activeConnections int
	connMu            sync.Mutex
)

func incConn() bool {
	connMu.Lock()
	defer connMu.Unlock()
	if activeConnections >= MaxConnectionsTotal {
		return false
	}
	activeConnections++
	return true
}

func decConn() {
	connMu.Lock()
	defer connMu.Unlock()
	activeConnections--
}

// ─────────────────────────────────────────────────────────────────────────────
// JWT Validation
// ─────────────────────────────────────────────────────────────────────────────

type Claims struct {
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	RoleLevel int    `json:"role_level"`
	ClassID   string `json:"class_id"`
	jwt.RegisteredClaims
}

func validateJWT(tokenStr string) (*Claims, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return nil, errors.New("JWT_SECRET not configured")
	}
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid token")
	}
	return claims, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Validation (Anti-Cheat)
// ─────────────────────────────────────────────────────────────────────────────

func validateInput(p *Player, input *PlayerInput) error {
	// Replay / sequence protection
	if input.Seq <= p.LastSeqSeen && p.LastSeqSeen > 0 {
		return errors.New("duplicate or replayed seq")
	}

	// Speed-hack detection: movement vector magnitude must not exceed 1.0
	mag := math.Sqrt(input.MoveX*input.MoveX + input.MoveY*input.MoveY)
	if mag > 1.0+0.01 { // tiny epsilon for float rounding
		return errors.New("move vector too large (speed hack)")
	}

	// Rotation must be a valid float (no NaN/Inf)
	if math.IsNaN(input.Rotation) || math.IsInf(input.Rotation, 0) {
		return errors.New("invalid rotation value")
	}

	// AttackFlags must be within a sane bitmask
	if input.AttackFlags < 0 || input.AttackFlags > 0xFF {
		return errors.New("invalid attack flags")
	}

	return nil
}

func validateAttack(p *Player) bool {
	return time.Since(p.LastAttackTime).Milliseconds() >= AttackCooldownMs
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Manager
// ─────────────────────────────────────────────────────────────────────────────

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
		PosX:    WorldBoundsX * 0.8, // Spawn near right edge
		PosY:    WorldBoundsY * 0.5,
		HP:      hp,
	}
	log.Printf("[ROOM %s] Spawned mob %s (%s) with %d HP", r.RoomID, mobID, mobType, hp)
}

// ─────────────────────────────────────────────────────────────────────────────
// Tick Loop
// ─────────────────────────────────────────────────────────────────────────────

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
		Difficulty: "Normal", // adjust based on logic
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

	// ─── Player Movement ───
	for _, p := range r.Players {
		p.mu.Lock()
		if len(p.InputQueue) > 0 {
			input := p.InputQueue[0]
			p.InputQueue = p.InputQueue[1:]

			p.LastPos = p.Pos
			applyInput(r, p, input)
			handleAttack(r, p, input)

			// Post-move speed validation (authoritative)
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

	// ─── Mob AI & Movement ───
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

		// Find nearest player
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
				// Mob attack logic
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

func applyInput(r *Room, p *Player, input PlayerInput) {
	speed := 2.5
	if p.Vitals.Speed > 0 {
		speed = p.Vitals.Speed / TickRate // convert pixels/sec to pixels/tick
	}
	
	p.Pos.X = clamp(p.Pos.X+input.MoveX*speed, 0, WorldBoundsX)
	p.Pos.Y = clamp(p.Pos.Y+input.MoveY*speed, 0, WorldBoundsY)
}

func handleAttack(r *Room, p *Player, input PlayerInput) {
	if input.AttackFlags == 0 {
		return
	}

	if !validateAttack(p) {
		return
	}

	damage := 10
	if p.Vitals.AttackDamage > 0 {
		damage = p.Vitals.AttackDamage
	}

	p.LastAttackTime = time.Now()

	// Simple circular AOE attack for MVP
	for mobID, m := range r.Mobs {
		dx := m.PosX - p.Pos.X
		dy := m.PosY - p.Pos.Y
		dist := math.Sqrt(dx*dx + dy*dy)

		if dist <= AttackRange {
			m.HP -= damage
			p.Vitals.DmgDealt += damage
			if m.HP <= 0 {
				configMu.RLock()
				mobCfg, ok := mobConfigs[m.MobType]
				configMu.RUnlock()

				goldReward := 5
				xpReward := 10
				if ok {
					goldReward = mobCfg.GoldReward
					xpReward = mobCfg.XPReward
				}

				delete(r.Mobs, mobID)
				p.Vitals.Kills++
				p.Vitals.Gold += goldReward
				p.Vitals.XP += xpReward
				
				// Level up calculation
				xpNeeded := p.Build.Level * 100
				if p.Vitals.XP >= xpNeeded {
					p.Build.Level++
					p.Vitals.XP -= xpNeeded
					
					configMu.RLock()
					classCfg, ok := classConfigs[p.ClassID]
					configMu.RUnlock()
					if ok {
						p.Vitals.MaxHP += classCfg.HealthPerLevel
						p.Vitals.HP = p.Vitals.MaxHP
						p.Vitals.AttackDamage += classCfg.DamagePerLevel
					}
					lvlMsg, _ := json.Marshal(map[string]any{
						"op": OP_LEVEL_UP, "user_id": p.UserID, "level": p.Build.Level,
					})
					r.broadcast(lvlMsg)
				}
				
				dieMsg, _ := json.Marshal(map[string]any{
					"op": OP_MOB_DIE, "mob_id": mobID, "killer_id": p.UserID,
					"xp_gain": xpReward, "gold_gain": goldReward,
				})
				r.broadcast(dieMsg)
			}
		}
	}
}

func clamp(v, min, max float64) float64 {
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

// ─────────────────────────────────────────────────────────────────────────────
// Broadcast Helpers
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket Upgrader — Origin-checked
// ─────────────────────────────────────────────────────────────────────────────

var allowedOrigins = func() map[string]bool {
	origins := map[string]bool{"localhost": true, "127.0.0.1": true}
	if extra := os.Getenv("ALLOWED_ORIGINS"); extra != "" {
		for _, o := range strings.Split(extra, ",") {
			origins[strings.TrimSpace(o)] = true
		}
	}
	return origins
}()

var upgrader = websocket.Upgrader{
	HandshakeTimeout: WSHandshakeTimeout,
	ReadBufferSize:   MaxMessageBytes,
	WriteBufferSize:  4 * 1024,
	CheckOrigin: func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		if origin == "" {
			return true // non-browser clients (Godot)
		}
		// Strip scheme
		origin = strings.TrimPrefix(strings.TrimPrefix(origin, "https://"), "http://")
		host := strings.Split(origin, ":")[0]
		return allowedOrigins[host]
	},
}

var roomManager = NewRoomManager()

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket Handler
// ─────────────────────────────────────────────────────────────────────────────

func wsHandler(w http.ResponseWriter, r *http.Request) {
	// 1. Global connection cap
	if !incConn() {
		http.Error(w, "server at capacity", http.StatusServiceUnavailable)
		return
	}

	q := r.URL.Query()

	// 2. Validate JWT (Bearer or ?token=)
	tokenStr := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	if tokenStr == "" {
		tokenStr = q.Get("token")
	}
	claims, err := validateJWT(tokenStr)
	if err != nil {
		decConn()
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	// 3. Validate room_id length
	roomID := q.Get("room_id")
	roomCode := q.Get("room_code")
	if roomID == "" || len(roomID) > MaxRoomIDLen {
		decConn()
		http.Error(w, "invalid room_id", http.StatusBadRequest)
		return
	}

	// 4. Upgrade
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		decConn()
		log.Printf("WS upgrade error: %v", err)
		return
	}
	// 5. Enforce max message size
	conn.SetReadLimit(MaxMessageBytes)

	room := roomManager.GetOrCreate(roomID, roomCode)

	// 6. Enforce max players per room
	room.mu.Lock()
	if len(room.Players) >= MaxPlayersPerRoom {
		room.mu.Unlock()
		_ = conn.WriteMessage(websocket.CloseMessage,
			websocket.FormatCloseMessage(websocket.ClosePolicyViolation, "room full"))
		conn.Close()
		decConn()
		return
	}

	configMu.RLock()
	classConfig, ok := classConfigs[claims.ClassID]
	configMu.RUnlock()

	hp := 100
	mana := 50
	dmg := 10
	speed := 60.0
	if ok {
		hp = classConfig.BaseMaxHealth
		mana = classConfig.BaseMaxMana
		dmg = classConfig.BaseAttackDamage
		speed = classConfig.BaseSpeed
	}

	player := &Player{
		UserID:        claims.UserID,
		ClassID:       claims.ClassID,
		Conn:          conn,
		Pos:           Vec2{X: WorldBoundsX / 2, Y: WorldBoundsY / 2},
		Vitals:        PlayerVitals{
			HP: hp, MaxHP: hp, Mana: mana, MaxMana: mana, 
			AttackDamage: dmg, Speed: speed, DeathState: DeathStateAlive,
		},
		Build:         PlayerBuild{Level: 1, Items: []string{}},
		LastInputTime: time.Now(),
		LastSeen:      time.Now(),
	}
	room.Players[claims.UserID] = player
	if room.HostID == "" {
		room.HostID = claims.UserID
	}
	room.mu.Unlock()

	joinMsg, _ := json.Marshal(map[string]any{"op": OP_PLAYER_JOIN, "user_id": claims.UserID})
	room.mu.RLock()
	room.broadcast(joinMsg)
	room.mu.RUnlock()

	log.Printf("[ROOM %s] Player %s joined (total: %d)", roomID, claims.UserID, len(room.Players))

	// 7. Message receive loop
	for {
		_, raw, err := conn.ReadMessage()
		if err != nil {
			handleDisconnect(room, player)
			decConn()
			return
		}
		// Reject oversized payloads (belt-and-suspenders)
		if len(raw) > MaxMessageBytes {
			log.Printf("[SECURITY] Oversized message from %s — dropped", claims.UserID)
			continue
		}
		var msgMap map[string]any
		if err := json.Unmarshal(raw, &msgMap); err != nil {
			continue
		}
		opCode, _ := msgMap["op"].(float64)
		handleMessage(room, player, int(opCode), msgMap)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Handler
// ─────────────────────────────────────────────────────────────────────────────

func handleMessage(room *Room, p *Player, op int, msg map[string]any) {
	switch op {
	case OP_INPUT:
		var input PlayerInput
		raw, _ := json.Marshal(msg)
		if err := json.Unmarshal(raw, &input); err != nil {
			return
		}
		// Anti-cheat validation
		if err := validateInput(p, &input); err != nil {
			log.Printf("[ANTICHEAT] Player %s invalid input: %v", p.UserID, err)
			return
		}
		p.mu.Lock()
		if len(p.InputQueue) >= InputQueueMax {
			p.InputQueue = p.InputQueue[1:]
		}
		p.InputQueue = append(p.InputQueue, input)
		p.LastSeqSeen = input.Seq
		p.mu.Unlock()

	case OP_START_GAME:
		room.mu.Lock()
		if p.UserID == room.HostID && room.State == StateLobby {
			room.State = StatePreWave
			startMsg, _ := json.Marshal(map[string]any{"op": OP_WAVE_START, "wave_num": 1})
			room.broadcast(startMsg)
			room.State = StateInWave
			room.WaveNum = 1
		}
		room.mu.Unlock()

	case OP_PLAYER_READY:
		room.mu.Lock()
		room.ReadySet[p.UserID] = true
		if len(room.ReadySet) == len(room.Players) && room.State == StateUpgradePhase {
			room.ReadySet = make(map[string]bool)
			room.State = StatePreWave
			nextWave, _ := json.Marshal(map[string]any{"op": OP_WAVE_START, "wave_num": room.WaveNum + 1})
			room.broadcast(nextWave)
			room.WaveNum++
			room.State = StateInWave
		}
		room.mu.Unlock()

	case OP_EMOTE:
		// Validate emote_id is a string, not arbitrary data
		emoteID, ok := msg["emote_id"].(string)
		if !ok || len(emoteID) > 32 {
			return
		}
		relay, _ := json.Marshal(map[string]any{
			"op": OP_EMOTE, "user_id": p.UserID, "emote_id": emoteID,
		})
		room.mu.RLock()
		room.broadcast(relay)
		room.mu.RUnlock()

	case OP_VOTE_KICK:
		targetID, ok := msg["target_user_id"].(string)
		if !ok || len(targetID) > MaxUserIDLen {
			return
		}
		// Don't allow kicking yourself
		if targetID == p.UserID {
			return
		}
		// Relay vote status (tallying omitted for brevity, extend as needed)
		voteMsg, _ := json.Marshal(map[string]any{
			"op": OP_VOTE_STATUS, "initiator": p.UserID, "target": targetID,
		})
		room.mu.RLock()
		room.broadcast(voteMsg)
		room.mu.RUnlock()

	case OP_BUY_ITEM:
		itemID, ok := msg["item_id"].(string)
		if !ok { return }
		configMu.RLock()
		itemCfg, hasItem := itemConfigs[itemID]
		configMu.RUnlock()
		if !hasItem { return }
		
		p.mu.Lock()
		defer p.mu.Unlock()
		if p.Vitals.Gold >= itemCfg.Price {
			p.Vitals.Gold -= itemCfg.Price
			p.Build.Items = append(p.Build.Items, itemID)
			
			if itemCfg.InstantHeal > 0 {
				p.Vitals.HP = int(math.Min(float64(p.Vitals.HP + itemCfg.InstantHeal), float64(p.Vitals.MaxHP)))
			}
			
			switch itemCfg.StatType {
			case "MAX_HP":
				p.Vitals.MaxHP += int(itemCfg.StatValue)
				p.Vitals.HP += int(itemCfg.StatValue)
			case "ATTACK":
				p.Vitals.AttackDamage += int(itemCfg.StatValue)
			case "SPEED":
				if itemCfg.Category == "percentage" {
					p.Vitals.Speed *= (1.0 + itemCfg.StatValue/100.0)
				} else {
					p.Vitals.Speed += itemCfg.StatValue
				}
			}
		}
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// Disconnect Handler
// ─────────────────────────────────────────────────────────────────────────────

func handleDisconnect(room *Room, p *Player) {
	log.Printf("[ROOM %s] Player %s disconnected — %ds grace", room.RoomID, p.UserID, DisconnectGraceSec)

	reconnMsg, _ := json.Marshal(map[string]any{
		"op": OP_PLAYER_RECONNECTING, "user_id": p.UserID, "grace_secs": DisconnectGraceSec,
	})
	room.mu.RLock()
	room.broadcast(reconnMsg)
	room.mu.RUnlock()

	time.Sleep(time.Duration(DisconnectGraceSec) * time.Second)

	room.mu.Lock()
	delete(room.Players, p.UserID)
	if room.HostID == p.UserID {
		for id := range room.Players {
			room.HostID = id
			break
		}
	}
	room.mu.Unlock()

	leaveMsg, _ := json.Marshal(map[string]any{"op": OP_PLAYER_LEAVE, "user_id": p.UserID})
	room.mu.RLock()
	room.broadcast(leaveMsg)
	room.mu.RUnlock()
}

// ─────────────────────────────────────────────────────────────────────────────
// Security Headers Middleware
// ─────────────────────────────────────────────────────────────────────────────

func secureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry Point
// ─────────────────────────────────────────────────────────────────────────────

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	if os.Getenv("JWT_SECRET") == "" {
		log.Fatal("[FATAL] JWT_SECRET env var is required")
	}

	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "redis:6379"
	}
	redisClient = redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})
	log.Printf("Connecting to Redis at %s...", redisAddr)

	fetchInitialConfig()
	go listenAdminCommands()
	go listenConfigUpdates()

	mux := http.NewServeMux()
	mux.HandleFunc("/ws", wsHandler)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok","service":"moon-game-server"}`))
	})

	_ = uuid.New()

	log.Printf("🌙 Moon Game Server :%s | Tickrate: %dHz | MaxConn: %d", port, TickRate, MaxConnectionsTotal)
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      secureHeaders(mux),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}

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
				// Disconnect all players
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

func fetchInitialConfig() {
	lobbyURL := os.Getenv("LOBBY_API_URL")
	if lobbyURL == "" {
		lobbyURL = "http://lobby-api:3000"
	}
	resp, err := http.Get(lobbyURL + "/game/config")
	if err != nil {
		log.Printf("[CONFIG] Failed to fetch initial config: %v", err)
		return
	}
	defer resp.Body.Close()

	var data struct {
		Mobs    []MobConfig    `json:"mobs"`
		Items   []ItemConfig   `json:"items"`
		Classes []ClassConfig  `json:"classes"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		log.Printf("[CONFIG] Decode error: %v", err)
		return
	}

	configMu.Lock()
	for _, m := range data.Mobs { mobConfigs[m.MobType] = m }
	for _, i := range data.Items { itemConfigs[i.ItemID] = i }
	for _, c := range data.Classes { classConfigs[c.ClassID] = c }
	configMu.Unlock()
	log.Printf("[CONFIG] Initialized: %d mobs, %d items, %d classes", len(data.Mobs), len(data.Items), len(data.Classes))
}

func listenConfigUpdates() {
	pubsub := redisClient.Subscribe(ctx, "config_updates")
	defer pubsub.Close()
	for {
		msg, err := pubsub.ReceiveMessage(ctx)
		if err != nil { continue }
		
		log.Printf("[CONFIG] Update received: %s", msg.Payload)
		// Simplest way to sync: just re-fetch everything
		// This is safe because updates are rare (admin tuning)
		fetchInitialConfig()
	}
}
