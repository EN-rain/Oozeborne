class_name PaladinClass extends PlayerClass

## Paladin - Holy tank with healing and defensive capabilities
## Good HP and defense, moderate damage

func _init():
	display_name = "Paladin"
	description = "A holy warrior blessed with divine power. Paladins combine solid defense with healing abilities."
	lore = "Chosen by the divine light, Paladins stand as beacons of hope in the darkest of times."
	
	# Player scene - Gold slime for holy classes
	
	# Stat modifiers
	modifiers_hp = 1.22       # +22% HP
	modifiers_speed = 0.9     # -10% Speed
	modifiers_damage = 1.05   # +5% Damage
	modifiers_defense = 1.18  # +18% Defense
	modifiers_attack_speed = 0.9    # -10% Attack Speed
	
	# Mana & Regen
	mana_bonus = 15         # +15 MP (holy magic)
	mana_regen_bonus = 0.5  # +0.5 MP/s
	hp_regen_bonus = 1.0    # +1.0 HP/s out of combat
