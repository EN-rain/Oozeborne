class_name ShopItem extends Resource

## ShopItem - Defines a purchasable item in the shop

enum ItemType {
	CONSUMABLE,      # One-time use (potions)
	PERMANENT_UPGRADE, # Permanent stat boost
	EQUIPMENT,       # Equippable gear
	SPECIAL          # Unique effects
}

enum StatType {
	NONE,
	MAX_HP,
	ATTACK,
	SPEED,
	DEFENSE,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	LIFESTEAL,
	DODGE_CHANCE,
	COIN_BOOST,
	XP_BOOST,
	ABILITY_COOLDOWN
}

@export var item_id: String = ""
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var price: int = 10
@export var max_stacks: int = 99  # For consumables

# Effect values
@export var stat_type: StatType = StatType.NONE
@export var stat_value: float = 0.0  # Amount to add/multiply
@export var is_percentage: bool = false  # True = %, False = flat

# For consumables with duration
@export var duration: float = 0.0  # 0 = instant
@export var instant_heal: int = 0  # HP healed instantly

# For equipment
@export var equipment_slot: String = ""  # "weapon", "boots", "ring", etc.

# Class restriction (empty = all classes)
@export var restricted_to_class: String = ""  # Class name or empty

# Whether player owns this (for permanent items)
var owned: bool = false
var quantity: int = 0


func can_afford(player_coins: int) -> bool:
	return player_coins >= price


func get_effect_description() -> String:
	if instant_heal > 0:
		return "Restore %d HP" % instant_heal
	
	if stat_type == StatType.NONE:
		return description
	
	var stat_name = stat_type_to_string()
	var value_str = ""
	if is_percentage:
		value_str = "%+.0f%%" % stat_value
	else:
		value_str = "%+.0f" % stat_value
	
	if duration > 0:
		return "%s %s for %.0fs" % [value_str, stat_name, duration]
	else:
		return "%s %s permanently" % [value_str, stat_name]


func stat_type_to_string() -> String:
	match stat_type:
		StatType.MAX_HP: return "Max HP"
		StatType.ATTACK: return "Attack"
		StatType.SPEED: return "Speed"
		StatType.DEFENSE: return "Defense"
		StatType.CRIT_CHANCE: return "Crit Chance"
		StatType.CRIT_DAMAGE: return "Crit Damage"
		StatType.LIFESTEAL: return "Lifesteal"
		StatType.DODGE_CHANCE: return "Dodge"
		StatType.COIN_BOOST: return "Coin Drop"
		StatType.XP_BOOST: return "XP Gain"
		StatType.ABILITY_COOLDOWN: return "Ability Cooldown"
		_: return "Stat"
