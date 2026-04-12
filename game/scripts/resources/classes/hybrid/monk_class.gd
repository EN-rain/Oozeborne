class_name MonkClass extends PlayerClass

## Monk - Unarmed fighter with combo system
## High speed and damage, dodge-based defense

func _init():
	display_name = "Monk"
	description = "A disciplined martial artist who fights with bare hands. Monks build combos for devastating finishers."
	lore = "Students of the Hidden Monastery, Monks have trained their bodies to become living weapons."
	
	
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
	
	# Mana & Regen
	mana_bonus = 5          # +5 MP (chi/energy user)
	mana_regen_bonus = 1.0  # +1.0 MP/s
	hp_regen_bonus = 0.5    # +0.5 HP/s out of combat
