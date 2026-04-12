class_name MageClass extends PlayerClass

## Mage - Glass cannon with devastating AoE spells
## Very high damage, very low HP and defense

func _init():
	display_name = "Mage"
	description = "Master of the arcane arts. Mages wield devastating spells but are extremely fragile."
	lore = "Scholars of the Arcane Academy, Mages have spent decades mastering the elemental forces."
	
	# Player scene - Purple slime for magic classes
	
	# Stat modifiers
	modifiers_hp = 0.78       # -22% HP
	modifiers_speed = 1.1     # +10% Speed
	modifiers_damage = 1.35   # +35% Damage
	modifiers_defense = 0.82  # -18% Defense
	modifiers_attack_speed = 0.95   # -5% Attack Speed
	modifiers_crit_chance = 1.06    # +6% Crit Chance
	modifiers_crit_damage = 1.20    # +20% Crit Damage
	
	# Mana & Regen
	mana_bonus = 50         # +50 MP (pure caster, highest pool)
	mana_regen_bonus = 1.0  # +1.0 MP/s
	hp_regen_bonus = 0.0
