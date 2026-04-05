class_name BardClass extends PlayerClass

## Bard - Versatile support with buffs and debuffs
## Balanced stats with aura effects

func _init():
	display_name = "Bard"
	description = "A wandering minstrel whose songs inspire allies and demoralize enemies. Bards provide powerful aura buffs."
	lore = "Graduates of the Bardic College, these performers weave magic into their melodies."
	
	# Player scene - Gold slime for performance classes
	player_scene = preload("res://scenes/entities/player/slime_gold.tscn")
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.15    # +15% Speed
	modifiers_damage = 0.9    # -10% Damage
	modifiers_defense = 1.05  # +5% Defense
	modifiers_attack_speed = 1.1     # +10% Attack Speed
	
	# Special ability
	ability_name = "Symphony of War"
	ability_description = "Play an inspiring song that grants all nearby allies +25% damage and +25% attack speed for 8 seconds."
	ability_cooldown = 20.0
	ability_duration = 8.0
	
	# Passive bonuses
	passive_name = "Inspiring Presence"
	passive_description = "Allies near you gain +10% damage. Enemies near you deal -10% damage."
	passive_gold_bonus = 20.0  # +20% gold from all sources
