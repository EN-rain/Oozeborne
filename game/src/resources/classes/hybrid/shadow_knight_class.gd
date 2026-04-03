class_name ShadowKnightClass extends PlayerClass

## Shadow Knight - Dark tank with lifesteal and sacrifice mechanics
## High HP, good damage, dark abilities

func _init():
	display_name = "Shadow Knight"
	description = "A fallen warrior who has embraced the darkness. Shadow Knights sacrifice their own HP to fuel devastating attacks."
	lore = "Once noble paladins, Shadow Knights made a pact with darkness to gain power at a terrible price."
	
	# Stat modifiers
	modifiers_hp = 1.2        # +20% HP
	modifiers_speed = 1.05    # +5% Speed
	modifiers_damage = 1.15   # +15% Damage
	modifiers_defense = 0.95  # -5% Defense
	modifiers_attack_speed = 1.0     # Normal Attack Speed
	
	# Special ability
	ability_name = "Dark Pact"
	ability_description = "Sacrifice 15% of current HP to deal 150 damage to all nearby enemies and heal for 50% of damage dealt."
	ability_cooldown = 10.0
	ability_duration = 0.0    # Instant
	
	# Passive bonuses
	passive_name = "Vampiric Embrace"
	passive_description = "Lifesteal is 50% more effective. Healing from abilities is 25% stronger."
	passive_lifesteal = 15.0  # 15% base lifesteal
