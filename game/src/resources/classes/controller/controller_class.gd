class_name ControllerClass extends PlayerClass

## Controller - Battlefield control specialist with zoning and crowd control
## Balanced baseline with stronger utility pressure

func _init():
	display_name = "Controller"
	description = "Area-control main class focused on slows, roots, and positional pressure."
	lore = "Controllers dominate space and momentum by constraining enemy movement and decision-making."
	
	# Class identity - controller is a main class
	is_main_class = true
	is_subclass = false
	
	# Player scene - Cyan slime for control archetype

	# Stat modifiers
	modifiers_hp = 1.0         # Base HP
	modifiers_speed = 1.03     # +3% Speed
	modifiers_damage = 1.08    # +8% Damage
	modifiers_defense = 1.0    # Base Defense
	modifiers_attack_speed = 1.02  # +2% Attack Speed
	modifiers_crit_chance = 1.05   # +5% Crit Chance

	# Special ability
	ability_name = "Control Field"
	ability_description = "Deploy a control zone that slows enemies and weakens their outgoing damage."
	ability_cooldown = 14.0
	ability_duration = 6.0

	# Passive bonuses
	passive_name = "Tempo Lock"
	passive_description = "Enemies affected by your control effects take bonus damage from your abilities."
