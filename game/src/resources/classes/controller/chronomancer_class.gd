class_name ChronomancerClass extends PlayerClass

## Chronomancer - Time-focused controller with slows and tempo manipulation
## Fast utility subclass with moderate damage

func _init():
	display_name = "Chronomancer"
	description = "Time weaver that slows enemies and manipulates cooldown tempo."
	lore = "Chronomancers bend local time to desync enemy rhythm and open safe windows for allies."
	
	# Player scene - Cyan slime for temporal control
	
	# Class identity - controller is a subclass
	is_main_class = false
	is_subclass = true

	# Stat modifiers
	modifiers_hp = 0.95        # -5% HP
	modifiers_speed = 1.1      # +10% Speed
	modifiers_damage = 1.1     # +10% Damage
	modifiers_defense = 0.95   # -5% Defense
	modifiers_attack_speed = 1.05   # +5% Attack Speed

	# Special ability
	ability_name = "Time Fracture"
	ability_description = "Create a temporal rift that heavily slows enemies inside and briefly hastes you on exit."
	ability_cooldown = 16.0
	ability_duration = 4.5

	# Passive bonuses
	passive_name = "Borrowed Seconds"
	passive_description = "Applying control effects grants a short cooldown reduction burst."
