class_name PaladinClass extends PlayerClass

## Paladin - Holy tank with healing and defensive capabilities
## Good HP and defense, moderate damage

func _init():
	display_name = "Paladin"
	description = "A holy warrior blessed with divine power. Paladins combine solid defense with healing abilities."
	lore = "Chosen by the divine light, Paladins stand as beacons of hope in the darkest of times."
	
	# Stat modifiers
	modifiers_hp = 1.3        # +30% HP
	modifiers_speed = 0.85    # -15% Speed
	modifiers_damage = 1.1    # +10% Damage
	modifiers_defense = 1.25  # +25% Defense
	modifiers_attack_speed = 0.9    # -10% Attack Speed
	
	# Special ability
	ability_name = "Divine Shield"
	ability_description = "Become invulnerable for 3 seconds and heal for 20% of max HP."
	ability_cooldown = 25.0
	ability_duration = 3.0
	
	# Passive bonuses
	passive_name = "Holy Light"
	passive_description = "Heal for 5% of damage dealt. Killing enemies grants an additional 10 HP heal."
	passive_lifesteal = 5.0
