class_name HybridRoleClass extends PlayerClass

## Hybrid - Main flexible class combining offense and utility
## Balanced stat spread across all core attributes

func _init():
	display_name = "Hybrid"
	description = "Balanced main class mixing offense and utility."
	lore = "Hybrids blend multiple combat disciplines to adapt to changing battlefield pressure."
	
	# Class identity - hybrid is a main class
	is_main_class = true
	is_subclass = false
	
	# Player scene - Purple slime for mixed archetype
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.05    # +5% Speed
	modifiers_damage = 1.05   # +5% Damage
	modifiers_defense = 1.0   # Base Defense
	modifiers_attack_speed = 1.05   # +5% Attack Speed
	modifiers_crit_chance = 1.06    # +6% Crit Chance
	modifiers_crit_damage = 1.08    # +8% Crit Damage
	
	# Mana & Regen
	mana_bonus = 10         # +10 MP (versatile magic)
	mana_regen_bonus = 0.5  # +0.5 MP/s
	hp_regen_bonus = 0.0
