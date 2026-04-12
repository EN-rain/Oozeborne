class_name DpsRoleClass extends PlayerClass

## DPS - Main damage class with strong elimination tempo
## High damage and speed, lighter defenses

func _init():
	display_name = "DPS"
	description = "Damage-focused main class built for fast eliminations."
	lore = "DPS specialists trade durability for tempo, looking to delete threats before they can retaliate."
	
	# Class identity - dps is a main class
	is_main_class = true
	is_subclass = false
	
	# Stat modifiers
	modifiers_hp = 0.95       # -5% HP
	modifiers_speed = 1.08    # +8% Speed
	modifiers_damage = 1.2    # +20% Damage
	modifiers_defense = 0.9   # -10% Defense
	modifiers_attack_speed = 1.1    # +10% Attack Speed
	modifiers_crit_chance = 1.08    # +8% Crit Chance
	modifiers_crit_damage = 1.10    # +10% Crit Damage
	
	# Passive bonuses
	passive_name = "Executioner"
	passive_description = "Deal bonus damage to low-health enemies."
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 0.0
