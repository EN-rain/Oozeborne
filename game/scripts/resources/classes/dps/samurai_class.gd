class_name SamuraiClass extends PlayerClass

## Samurai - Balanced DPS with dash attacks and iaijutsu
## High damage and speed, moderate defense

func _init():
	display_name = "Samurai"
	description = "A master of the blade. Samurai combine speed and precision with devastating quick-draw techniques."
	lore = "Followers of the Way of the Sword, Samurai seek perfection in every strike."
	
	# Player scene - Red slime for warrior classes
	
	# Stat modifiers
	modifiers_hp = 0.85       # -15% HP
	modifiers_speed = 1.15    # +15% Speed
	modifiers_damage = 1.24   # +24% Damage
	modifiers_defense = 0.85  # -15% Defense
	modifiers_attack_speed = 1.2    # +20% Attack Speed
	modifiers_crit_chance = 1.08    # +8% Crit Chance
	modifiers_crit_damage = 1.4     # +40% Crit Damage
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 0.0
