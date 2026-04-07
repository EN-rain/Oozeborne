class_name HybridRoleClass extends PlayerClass

## Hybrid - Main flexible class combining offense and utility
## Balanced stat spread across all core attributes

func _init():
	display_name = "Hybrid"
	description = "Balanced main class mixing offense and utility."
	lore = "Hybrids blend multiple combat disciplines to adapt to changing battlefield pressure."
	
	# Class identity - hybrid is a main class
	is_main_class = true
	is_subclass = false
	
	# Player scene - Purple slime for mixed archetype
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.05    # +5% Speed
	modifiers_damage = 1.05   # +5% Damage
	modifiers_defense = 1.0   # Base Defense
	modifiers_attack_speed = 1.05   # +5% Attack Speed
	
	# Special ability
	ability_name = "Adaptive Stance"
	ability_description = "Shift stance to gain situational bonuses in combat."
	ability_cooldown = 13.0
	ability_duration = 5.0
	
	# Passive bonuses
	passive_name = "Versatility"
	passive_description = "Gain small bonuses to multiple stats."
