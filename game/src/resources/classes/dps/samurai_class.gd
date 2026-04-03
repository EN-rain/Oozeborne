class_name SamuraiClass extends PlayerClass

## Samurai - Balanced DPS with dash attacks and iaijutsu
## High damage and speed, moderate defense

func _init():
	display_name = "Samurai"
	description = "A master of the blade. Samurai combine speed and precision with devastating quick-draw techniques."
	lore = "Followers of the Way of the Sword, Samurai seek perfection in every strike."
	
	# Stat modifiers
	modifiers_hp = 0.85       # -15% HP
	modifiers_speed = 1.15    # +15% Speed
	modifiers_damage = 1.3    # +30% Damage
	modifiers_defense = 0.85  # -15% Defense
	modifiers_attack_speed = 1.25   # +25% Attack Speed
	modifiers_crit_damage = 1.5     # +50% Crit Damage
	
	# Special ability
	ability_name = "Iaijutsu"
	ability_description = "Sheathe your blade for up to 2 seconds. Release to unleash a devastating slash that deals 3x damage and pierces enemies."
	ability_cooldown = 10.0
	ability_duration = 2.0
	
	# Passive bonuses
	passive_name = "Way of the Warrior"
	passive_description = "Consecutive hits on the same enemy increase damage by 5% per hit, stacking up to 25%."
	passive_dodge_chance = 5.0
