class_name AlchemistClass extends PlayerClass

## Alchemist - Debuff specialist with potions and DoT
## Balanced stats with utility items

func _init():
	display_name = "Alchemist"
	description = "A master of potions and poisons. Alchemists debilitate enemies with various concoctions."
	lore = "Members of the Alchemist Guild, they seek to unlock the secrets of transmutation."
	
	# Player scene - Green slime for utility classes
	player_scene = preload("res://scenes/entities/player/slime_green.tscn")
	
	# Stat modifiers
	modifiers_hp = 0.95       # -5% HP
	modifiers_speed = 1.05    # +5% Speed
	modifiers_damage = 1.05   # +5% Damage
	modifiers_defense = 1.05  # +5% Defense
	modifiers_attack_speed = 1.0     # Normal Attack Speed
	
	# Special ability
	ability_name = "Plague Flask"
	ability_description = "Throw a flask that creates a poison cloud, dealing 80 damage over 6 seconds and applying Vulnerability to all enemies inside."
	ability_cooldown = 15.0
	ability_duration = 6.0
	
	# Passive bonuses
	passive_name = "Transmutation"
	passive_description = "Potions and consumables are 50% more effective. Gain 10% chance to apply Poison on hit."
	passive_gold_bonus = 10.0
	passive_xp_bonus = 10.0
