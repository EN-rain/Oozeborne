package main

import "time"

// Constants
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

	MaxMessageBytes    = 4 * 1024
	MaxPlayersPerRoom  = 4
	MaxConnectionsTotal = 200
	MaxMoveSpeed       = 4.0
	MaxRoomIDLen       = 64
	MaxUserIDLen       = 64
	WSHandshakeTimeout = 5 * time.Second
	WriteTimeout       = 10 * time.Second
)

// OpCodes
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
	OP_CAST_SKILL_1        = 22
	OP_CAST_SKILL_2        = 23
	OP_CAST_SPECIAL        = 24
	OP_EFFECT_APPLY        = 25
	OP_EFFECT_REMOVE       = 26
)

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
	HP           int        `json:"hp"`
	MaxHP        int        `json:"max_hp"`
	Mana         int        `json:"mana"`
	MaxMana      int        `json:"max_mana"`
	AttackDamage int        `json:"attack_damage"`
	Speed        float64    `json:"speed"`
	DeathState   DeathState `json:"death_state"`
	Kills        int        `json:"kills"`
	DmgDealt     int        `json:"dmg_dealt"`
	Gold         int        `json:"gold"`
	XP           int        `json:"xp"`
	PingRTT      int                `json:"ping_rtt_ms"`
	IsAFK        bool               `json:"is_afk"`
	Attributes   map[string]float64 `json:"attributes"`
}

type PlayerBuild struct {
	Level int      `json:"level"`
	Items []string `json:"items"`
}

type MobState struct {
	MobID          string    `json:"mob_id"`
	MobType        string    `json:"mob_type"`
	PosX           float64   `json:"pos_x"`
	PosY           float64   `json:"pos_y"`
	HP             int                 `json:"hp"`
	LastAttackTime time.Time           `json:"-"`
	Cooldowns      map[string]time.Time `json:"-"`
}
