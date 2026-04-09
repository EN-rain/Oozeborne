class_name SpellbladeClass extends PlayerClass

## Spellblade - Melee and magic hybrid
## Balanced stats with elemental enchantments

func _init():
	display_name = "Spellblade"
	description = "A warrior who has mastered both steel and sorcery. Spellblades enchant their weapons with elemental magic."
	lore = "Outcasts from both the Warrior Academy and Arcane Institute, Spellblades forged their own path."
	
	# Player scene - Purple slime for magic-melee hybrid
	
	# Class identity - hybrid is a subclass
	is_main_class = false
	is_subclass = true
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.08    # +8% Speed
	modifiers_damage = 1.18   # +18% Damage
	modifiers_defense = 0.94  # -6% Defense
	modifiers_attack_speed = 1.08    # +8% Attack Speed
	modifiers_crit_chance = 1.08     # +8% Crit Chance
	modifiers_crit_damage = 1.15     # +15% Crit Damage
	
	# Special ability
	ability_name = "Elemental Infusion"
	ability_description = "Enchant your weapon with fire, ice, or lightning for 10 seconds. Each element provides unique effects: Fire (burn), Ice (slow), Lightning (chain damage)."
	ability_cooldown = 12.0
	ability_duration = 10.0
	
	# Passive bonuses
	passive_name = "Arcane Strike"
	passive_description = "Every 4th attack deals bonus magic damage equal to 30% of your attack damage."
	passive_lifesteal = 3.0
