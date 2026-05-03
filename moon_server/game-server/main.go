package main

import (
	"context"
	"encoding/json"
	"log"
	"math"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

var (
	ctx         = context.Background()
	redisClient *redis.Client

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
			return true
		}
		origin = strings.TrimPrefix(strings.TrimPrefix(origin, "https://"), "http://")
		host := strings.Split(origin, ":")[0]
		return allowedOrigins[host]
	},
}

var roomManager = NewRoomManager()

func wsHandler(w http.ResponseWriter, r *http.Request) {
	if !incConn() {
		http.Error(w, "server at capacity", http.StatusServiceUnavailable)
		return
	}

	q := r.URL.Query()
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

	roomID := q.Get("room_id")
	roomCode := q.Get("room_code")
	if roomID == "" || len(roomID) > MaxRoomIDLen {
		decConn()
		http.Error(w, "invalid room_id", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		decConn()
		log.Printf("WS upgrade error: %v", err)
		return
	}
	conn.SetReadLimit(MaxMessageBytes)

	room := roomManager.GetOrCreate(roomID, roomCode)

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
	classConfig, ok1 := classConfigs[claims.ClassID]
	subClassConfig, ok2 := classConfigs[claims.SubclassID]
	configMu.RUnlock()

	hp := 100
	mana := 50
	dmg := 10
	speed := 60.0
	attributes := make(map[string]float64)

	// Apply base stats and attributes from Main Class
	if ok1 {
		hp = classConfig.BaseMaxHealth
		mana = classConfig.BaseMaxMana
		dmg = classConfig.BaseAttackDamage
		speed = classConfig.BaseSpeed
		for k, v := range classConfig.Attributes {
			if val, ok := v.(float64); ok {
				attributes[k] += val
			}
		}
	}

	// Apply stats and attributes from Subclass at 50% efficiency
	if ok2 && claims.SubclassID != claims.ClassID && claims.SubclassID != "base" && claims.SubclassID != "" {
		hp += (subClassConfig.BaseMaxHealth - 100) / 2
		mana += (subClassConfig.BaseMaxMana - 50) / 2
		dmg += (subClassConfig.BaseAttackDamage - 10) / 2
		speed += (subClassConfig.BaseSpeed - 60.0) / 2
		
		for k, v := range subClassConfig.Attributes {
			if val, ok := v.(float64); ok {
				attributes[k] += (val * 0.5)
			}
		}
	}

	player := &Player{
		UserID:     claims.UserID,
		ClassID:    claims.ClassID,
		SubclassID: claims.SubclassID,
		Conn:       conn,
		Pos:        Vec2{X: WorldBoundsX / 2, Y: WorldBoundsY / 2},
		Vitals: PlayerVitals{
			HP: hp, MaxHP: hp, Mana: mana, MaxMana: mana,
			AttackDamage: dmg, Speed: speed, DeathState: DeathStateAlive,
			Attributes: attributes,
		},
		Build:         PlayerBuild{Level: 1, Items: []string{}},
		LastInputTime: time.Now(),
		LastSeen:      time.Now(),
		Cooldowns:     make(map[string]time.Time),
		ActiveEffects: make(map[string]time.Time),
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

	for {
		_, raw, err := conn.ReadMessage()
		if err != nil {
			handleDisconnect(room, player)
			decConn()
			return
		}
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

func handleMessage(room *Room, p *Player, op int, msg map[string]any) {
	switch op {
	case OP_INPUT:
		var input PlayerInput
		raw, _ := json.Marshal(msg)
		if err := json.Unmarshal(raw, &input); err != nil {
			return
		}
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

	case OP_MESSAGE:
		// Relay generic lobby/gameplay messages (chat, player_info, class_selected, etc.).
		msg["op"] = OP_MESSAGE
		msg["user_id"] = p.UserID
		relay, err := json.Marshal(msg)
		if err != nil {
			return
		}
		room.mu.RLock()
		room.broadcast(relay)
		room.mu.RUnlock()

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

	case OP_CAST_SKILL_1:
		activateSkill(room, p, 1)
	case OP_CAST_SKILL_2:
		activateSkill(room, p, 2)
	case OP_CAST_SPECIAL:
		activateSkill(room, p, 0) // Special is index 0 in config

	case OP_EMOTE:
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
		if targetID == p.UserID {
			return
		}
		voteMsg, _ := json.Marshal(map[string]any{
			"op": OP_VOTE_STATUS, "initiator": p.UserID, "target": targetID,
		})
		room.mu.RLock()
		room.broadcast(voteMsg)
		room.mu.RUnlock()

	case OP_BUY_ITEM:
		itemID, ok := msg["item_id"].(string)
		if !ok {
			return
		}
		configMu.RLock()
		itemCfg, hasItem := itemConfigs[itemID]
		configMu.RUnlock()
		if !hasItem {
			return
		}

		p.mu.Lock()
		defer p.mu.Unlock()
		if p.Vitals.Gold >= itemCfg.Price {
			p.Vitals.Gold -= itemCfg.Price
			p.Build.Items = append(p.Build.Items, itemID)

			if itemCfg.InstantHeal > 0 {
				p.Vitals.HP = int(math.Min(float64(p.Vitals.HP+itemCfg.InstantHeal), float64(p.Vitals.MaxHP)))
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
			case "MANA":
				p.Vitals.MaxMana += int(itemCfg.StatValue)
				p.Vitals.Mana += int(itemCfg.StatValue)
			default:
				// Dynamic attribute support (Lifesteal, Dodge, etc.)
				if itemCfg.StatType != "" {
					p.Vitals.Attributes[strings.ToLower(itemCfg.StatType)] += itemCfg.StatValue
				}
			}
		}
	}
}

func activateSkill(r *Room, p *Player, skillIdx int) {
	p.mu.Lock()
	defer p.mu.Unlock()

	configMu.RLock()
	classCfg, ok := classConfigs[p.ClassID]
	configMu.RUnlock()

	if !ok || skillIdx >= len(classCfg.Skills) {
		return
	}

	skill := classCfg.Skills[skillIdx]
	cooldownKey := "skill_" + skill.Name
	if lastUsed, exists := p.Cooldowns[cooldownKey]; exists {
		// Calculate cooldown from params[0] or default
		cd := 5.0
		if len(skill.Params) > 0 {
			cd = skill.Params[0].Init // Assumes P1 is cooldown if not labeled otherwise
		}
		if time.Since(lastUsed).Seconds() < cd {
			return
		}
	}

	// Unlocked check (Special at level 10)
	if skill.Type == "Special" && p.Build.Level < 10 {
		return
	}

	// Consume Mana
	manaCost := 10.0 // Default
	if p.Vitals.Mana < int(manaCost) {
		return
	}
	p.Vitals.Mana -= int(manaCost)

	// Mark Cooldown
	p.Cooldowns[cooldownKey] = time.Now()

	// Broadcast Skill Activation
	castMsg, _ := json.Marshal(map[string]any{
		"op": OP_EFFECT_APPLY, "user_id": p.UserID, "skill_name": skill.Name,
	})
	r.broadcast(castMsg)

	log.Printf("[SKILL] Player %s cast %s", p.UserID, skill.Name)

	// Apply immediate effects based on skill name
	switch skill.Name {
	case "Fortify":
		p.ActiveEffects["dmg_red"] = time.Now().Add(3 * time.Second)
	case "Adrenaline":
		p.ActiveEffects["atk_boost"] = time.Now().Add(5 * time.Second)
	case "Frenzy":
		p.ActiveEffects["atk_spd_boost"] = time.Now().Add(4 * time.Second)
	}
}

func processEffects(p *Player) {
	p.mu.Lock()
	defer p.mu.Unlock()

	for effect, expiry := range p.ActiveEffects {
		if time.Now().After(expiry) {
			delete(p.ActiveEffects, effect)
			// Optional: Broadcast effect removal
		}
	}
}

func secureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}

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
