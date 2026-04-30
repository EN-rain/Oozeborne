package main

import (
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
)

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
	MaxHP      int        `json:"max_hp"`
	DeathState DeathState `json:"death_state"`
	PingRTT    int        `json:"ping_rtt_ms"`
	IsAFK      bool       `json:"is_afk"`
}

type PlayerBuild struct {
	Level int      `json:"level"`
	Items []string `json:"items"`
}

type Player struct {
	UserID           string
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
	PosY    float64 `json:"pos_y"`
	HP      int     `json:"hp"`
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

// ─────────────────────────────────────────────────────────────────────────────
// Tick Loop
// ─────────────────────────────────────────────────────────────────────────────

func (r *Room) tickLoop() {
	ticker := time.NewTicker(TickInterval)
	defer ticker.Stop()
	for {
		select {
		case <-r.tickStop:
			return
		case <-ticker.C:
			r.tick()
		}
	}
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
			applyInput(p, input)

			// Post-move speed validation (authoritative)
			dx := p.Pos.X - p.LastPos.X
			dy := p.Pos.Y - p.LastPos.Y
			if math.Sqrt(dx*dx+dy*dy) > MaxMoveSpeed {
				// Rollback to last valid position
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

	r.broadcastState()
}

func applyInput(p *Player, input PlayerInput) {
	const speed = 2.5
	p.Pos.X = clamp(p.Pos.X+input.MoveX*speed, 0, WorldBoundsX)
	p.Pos.Y = clamp(p.Pos.Y+input.MoveY*speed, 0, WorldBoundsY)
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

	player := &Player{
		UserID:        claims.UserID, // from verified JWT — not query param
		Conn:          conn,
		Pos:           Vec2{X: WorldBoundsX / 2, Y: WorldBoundsY / 2},
		Vitals:        PlayerVitals{HP: 100, MaxHP: 100, DeathState: DeathStateAlive},
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
