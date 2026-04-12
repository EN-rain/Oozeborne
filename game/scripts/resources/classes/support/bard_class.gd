class_name BardClass extends PlayerClass

## Bard - Versatile support with buffs and debuffs
## Balanced stats with aura effects

func _init():
	display_name = "Bard"
	description = "A wandering minstrel whose songs inspire allies and demoralize enemies. Bards provide powerful aura buffs."
	lore = "Graduates of the Bardic College, these performers weave magic into their melodies."
	
	# Player scene - Gold slime for performance classes
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.15    # +15% Speed
	modifiers_damage = 0.9    # -10% Damage
	modifiers_defense = 1.05  # +5% Defense
	modifiers_attack_speed = 1.1     # +10% Attack Speed
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 0.0
