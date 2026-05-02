package main

import (
	"encoding/json"
	"log"
	"math"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type Player struct {
	UserID         string
	ClassID        string
	Conn           *websocket.Conn
	Pos            Vec2
	LastPos        Vec2
	Vitals         PlayerVitals
	Build          PlayerBuild
	InputQueue     []PlayerInput
	LastInputTime  time.Time
	LastAttackTime time.Time
	LastSeen       time.Time
	PingSentAt     time.Time
	LastSeqSeen    int
	mu             sync.Mutex
}

func applyInput(r *Room, p *Player, input PlayerInput) {
	speed := 2.5
	if p.Vitals.Speed > 0 {
		speed = p.Vitals.Speed / TickRate
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
