class_name HexbinderClass extends PlayerClass

## Hexbinder - Curse controller focused on debuff pressure
## Fragile utility subclass with high spell amplification

func _init():
	display_name = "Hexbinder"
	description = "Curse specialist that weakens enemies and amplifies team burst."
	lore = "Hexbinders use layered curses to choke enemy output and punish overcommitment."
	
	# Player scene - Purple slime for curse casters
	
	# Class identity - controller is a subclass
	is_main_class = false
	is_subclass = true

	# Stat modifiers
	modifiers_hp = 0.92        # -8% HP
	modifiers_speed = 1.02     # +2% Speed
	modifiers_damage = 1.15    # +15% Damage
	modifiers_defense = 0.9    # -10% Defense
	modifiers_attack_speed = 1.06   # +6% Attack Speed

	# Special ability
	ability_name = "Severing Hex"
	ability_description = "Mark enemies in a cone; marked targets deal less damage and take bonus ability damage."
	ability_cooldown = 13.0
	ability_duration = 6.0

	# Passive bonuses
	passive_name = "Malice Chain"
	passive_description = "Defeated cursed enemies spread a weaker curse to nearby targets."
