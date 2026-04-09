class_name AssassinClass extends PlayerClass

## Assassin - High mobility, high burst damage, low survivability
## Critical hits deal massive damage

func _init():
	display_name = "Assassin"
	description = "A shadow in the night. Assassins strike from the darkness, dealing devastating critical hits."
	lore = "Masters of the silent kill, Assassins are trained in the forbidden arts of the Shadow Guild."
	
	# Player scene - Red slime for aggressive DPS
	
	# Stat modifiers
	modifiers_hp = 0.82       # -18% HP
	modifiers_speed = 1.22    # +22% Speed
	modifiers_damage = 1.28   # +28% Damage
	modifiers_defense = 0.8   # -20% Defense
	modifiers_attack_speed = 1.18   # +18% Attack Speed
	modifiers_crit_chance = 1.28    # +28% Crit Chance
	modifiers_crit_damage = 1.55    # +55% Crit Damage
	
	# Special ability
	ability_name = "Shadow Step"
	ability_description = "Instantly teleport behind the nearest enemy and gain 100% crit chance for your next attack."
	ability_cooldown = 8.0
	ability_duration = 2.0
	
	# Passive bonuses
	passive_name = "Backstab"
	passive_description = "Attacks from behind deal 50% bonus damage and always crit."
	passive_dodge_chance = 10.0  # 10% dodge chance
