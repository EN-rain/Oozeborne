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
	
	# Special ability
	ability_name = "Burst Window"
	ability_description = "Temporarily increase attack and crit output."
	ability_cooldown = 12.0
	ability_duration = 4.0
	
	# Passive bonuses
	passive_name = "Executioner"
	passive_description = "Deal bonus damage to low-health enemies."
