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
	
	# Special ability
	ability_name = "Meteor Storm"
	ability_description = "Call down a rain of meteors in a large area, dealing 200 total damage over 3 seconds."
	ability_cooldown = 20.0
	ability_duration = 3.0
	
	# Passive bonuses
	passive_name = "Mana Shield"
	passive_description = "Convert 10% of damage taken into a temporary mana shield that regenerates over time."
	passive_thorns_damage = 10.0  # 10 magic damage to attackers
