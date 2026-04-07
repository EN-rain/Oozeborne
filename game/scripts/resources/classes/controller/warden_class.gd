class_name WardenClass extends PlayerClass

## Warden - Defensive controller with roots and lane denial
## Durable subclass with lower mobility

func _init():
	display_name = "Warden"
	description = "Defensive controller that blocks paths and pins enemies in place."
	lore = "Wardens shape terrain and hold lines, forcing enemies to fight on your terms."
	
	# Player scene - Blue slime for defensive controllers
	
	# Class identity - controller is a subclass
	is_main_class = false
	is_subclass = true

	# Stat modifiers
	modifiers_hp = 1.15        # +15% HP
	modifiers_speed = 0.95     # -5% Speed
	modifiers_damage = 1.0     # Base Damage
	modifiers_defense = 1.15   # +15% Defense
	modifiers_attack_speed = 0.95   # -5% Attack Speed

	# Special ability
	ability_name = "Bastion Ring"
	ability_description = "Raise a short-lived ring that slows crossing enemies and briefly roots the first target hit."
	ability_cooldown = 18.0
	ability_duration = 5.0

	# Passive bonuses
	passive_name = "Line Holder"
	passive_description = "Enemies near your control zones deal less damage."
