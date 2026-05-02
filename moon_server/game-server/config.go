package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
)

var (
	configMu     sync.RWMutex
	mobConfigs   = make(map[string]MobConfig)
	itemConfigs  = make(map[string]ItemConfig)
	classConfigs = make(map[string]ClassConfig)
)

type MobConfig struct {
	MobType    string                 `json:"mob_type"`
	Health     int                    `json:"health"`
	Speed      float64                `json:"speed"`
	Damage     int                    `json:"damage"`
	XPReward   int                    `json:"xp_reward"`
	GoldReward int                    `json:"gold_reward"`
	Attributes map[string]interface{} `json:"attributes"`
	Category   string                 `json:"category"`
	Skills     []Skill                `json:"skills"`
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
	Name     string             `json:"name"`
	Desc     string             `json:"desc"`
	Cooldown float64            `json:"cooldown,omitempty"`
	Value    float64            `json:"value,omitempty"`
	Extra    map[string]float64 `json:"extra,omitempty"`
}

type ClassConfig struct {
	ClassID          string                 `json:"class_id"`
	DisplayName      string                 `json:"display_name"`
	BaseMaxHealth    int                    `json:"base_max_health"`
	BaseSpeed        float64                `json:"base_speed"`
	BaseAttackDamage int                    `json:"base_attack_damage"`
	BaseCritChance   float64                `json:"base_crit_chance"`
	BaseMaxMana      int                    `json:"base_max_mana"`
	HealthPerLevel   int                    `json:"health_per_level"`
	DamagePerLevel   int                    `json:"damage_per_level"`
	Attributes       map[string]interface{} `json:"attributes"`
	Skills           []Skill                `json:"skills"`
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
	for _, m := range data.Mobs { 
		if m.Health < 0 { m.Health = 0 }
		if m.Speed < 0 { m.Speed = 0 }
		if m.Damage < 0 { m.Damage = 0 }
		mobConfigs[m.MobType] = m 
	}
	for _, i := range data.Items { itemConfigs[i.ItemID] = i }
	for _, c := range data.Classes { 
		if c.BaseMaxHealth < 0 { c.BaseMaxHealth = 0 }
		if c.BaseSpeed < 0 { c.BaseSpeed = 0 }
		if c.BaseAttackDamage < 0 { c.BaseAttackDamage = 0 }
		if c.BaseCritChance < 0 { c.BaseCritChance = 0 }
		if c.BaseMaxMana < 0 { c.BaseMaxMana = 0 }
		if c.HealthPerLevel < 0 { c.HealthPerLevel = 0 }
		if c.DamagePerLevel < 0 { c.DamagePerLevel = 0 }
		classConfigs[c.ClassID] = c 
	}
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
		fetchInitialConfig()
	}
}
