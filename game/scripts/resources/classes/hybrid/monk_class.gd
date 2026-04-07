class_name MonkClass extends PlayerClass

## Monk - Unarmed fighter with combo system
## High speed and damage, dodge-based defense

func _init():
	display_name = "Monk"
	description = "A disciplined martial artist who fights with bare hands. Monks build combos for devastating finishers."
	lore = "Students of the Hidden Monastery, Monks have trained their bodies to become living weapons."
	
	# Player scene - Red slime for martial artist classes
	
	# Class identity - hybrid is a subclass
	is_main_class = false
	is_subclass = true
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.18    # +18% Speed
	modifiers_damage = 1.14   # +14% Damage
	modifiers_defense = 1.0   # Neutral Defense
	modifiers_attack_speed = 1.2     # +20% Attack Speed
	modifiers_crit_chance = 1.15     # +15% Crit Chance
	
	# Special ability
	ability_name = "Seven-Point Strike"
	ability_description = "Unleash a rapid combo of 7 strikes, each dealing 20 damage. The final strike is guaranteed to crit and stun for 1 second."
	ability_cooldown = 15.0
	ability_duration = 2.0
	
	# Passive bonuses
	passive_name = "Flow State"
	passive_description = "Dodging an attack grants +20% attack speed for 3 seconds. Each consecutive hit increases dodge chance by 2% (max 20%)."
	passive_dodge_chance = 15.0  # 15% base dodge
