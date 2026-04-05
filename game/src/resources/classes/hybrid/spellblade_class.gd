class_name SpellbladeClass extends PlayerClass

## Spellblade - Melee and magic hybrid
## Balanced stats with elemental enchantments

func _init():
	display_name = "Spellblade"
	description = "A warrior who has mastered both steel and sorcery. Spellblades enchant their weapons with elemental magic."
	lore = "Outcasts from both the Warrior Academy and Arcane Institute, Spellblades forged their own path."
	
	# Player scene - Purple slime for magic-melee hybrid
	player_scene = preload("res://scenes/entities/player/slime_purple.tscn")
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.1     # +10% Speed
	modifiers_damage = 1.25   # +25% Damage
	modifiers_defense = 0.9   # -10% Defense
	modifiers_attack_speed = 1.1     # +10% Attack Speed
	
	# Special ability
	ability_name = "Elemental Infusion"
	ability_description = "Enchant your weapon with fire, ice, or lightning for 10 seconds. Each element provides unique effects: Fire (burn), Ice (slow), Lightning (chain damage)."
	ability_cooldown = 12.0
	ability_duration = 10.0
	
	# Passive bonuses
	passive_name = "Arcane Strike"
	passive_description = "Every 4th attack deals bonus magic damage equal to 30% of your attack damage."
	passive_lifesteal = 3.0
