class_name GuardianClass extends PlayerClass

## Guardian - Tank class focused on defense and protecting allies
## High HP and defense, low speed and damage

func _init():
	display_name = "Guardian"
	description = "An unbreakable wall of steel. Guardians excel at absorbing damage and protecting allies."
	lore = "Trained in the ancient arts of protection, Guardians have sworn to shield the weak from harm."
	
	# Player scene - Blue slime for tank classes
	
	# Stat modifiers
	modifiers_hp = 1.35       # +35% HP
	modifiers_speed = 0.85    # -15% Speed
	modifiers_damage = 0.9    # -10% Damage
	modifiers_defense = 1.3   # +30% Defense
	modifiers_attack_speed = 0.9   # -10% Attack Speed
	
	# Passive bonuses
	passive_name = "Iron Will"
	passive_description = "Gain 5% damage reduction for each nearby ally."
	passive_thorns_damage = 5.0  # Reflects 5 damage when hit
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 1.5    # +1.5 HP/s out of combat
