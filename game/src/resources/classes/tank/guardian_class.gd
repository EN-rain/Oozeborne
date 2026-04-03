class_name GuardianClass extends PlayerClass

## Guardian - Tank class focused on defense and protecting allies
## High HP and defense, low speed and damage

func _init():
	display_name = "Guardian"
	description = "An unbreakable wall of steel. Guardians excel at absorbing damage and protecting allies."
	lore = "Trained in the ancient arts of protection, Guardians have sworn to shield the weak from harm."
	
	# Stat modifiers
	modifiers_hp = 1.5        # +50% HP
	modifiers_speed = 0.8     # -20% Speed
	modifiers_damage = 0.9    # -10% Damage
	modifiers_defense = 1.4   # +40% Defense
	modifiers_attack_speed = 0.85  # -15% Attack Speed
	
	# Special ability
	ability_name = "Shield Wall"
	ability_description = "Raise your shield, reducing all incoming damage by 70% for 4 seconds and taunting nearby enemies."
	ability_cooldown = 15.0
	ability_duration = 4.0
	
	# Passive bonuses
	passive_name = "Iron Will"
	passive_description = "Gain 5% damage reduction for each nearby ally."
	passive_thorns_damage = 5.0  # Reflects 5 damage when hit
