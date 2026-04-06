class_name StormcallerClass extends PlayerClass

## Stormcaller - Aggressive controller with knockback and chain shocks
## Mobile subclass with sustained control pressure

func _init():
	display_name = "Stormcaller"
	description = "Aggressive controller that displaces enemies with chained lightning bursts."
	lore = "Stormcallers command volatile fronts that scatter formations and punish clustering."
	
	# Player scene - Teal slime for lightning archetype
	
	# Class identity - controller is a subclass
	is_main_class = false
	is_subclass = true

	# Stat modifiers
	modifiers_hp = 0.96        # -4% HP
	modifiers_speed = 1.12     # +12% Speed
	modifiers_damage = 1.12    # +12% Damage
	modifiers_defense = 0.92   # -8% Defense
	modifiers_attack_speed = 1.1    # +10% Attack Speed

	# Special ability
	ability_name = "Tempest Pulse"
	ability_description = "Release chained shockwaves that knock enemies back and apply a brief slow."
	ability_cooldown = 12.0
	ability_duration = 3.0

	# Passive bonuses
	passive_name = "Static Build"
	passive_description = "Repeated hits on controlled targets increase your lightning damage."
