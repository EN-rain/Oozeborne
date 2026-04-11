extends Node

## ShopManager - Singleton managing shop items and purchases
## Add to AutoLoad as "ShopManager"

signal item_purchased(item: ShopItem, success: bool)
signal shop_opened()
signal shop_closed()

# All available items
var all_items: Array[ShopItem] = []

# Categories for organization
var consumables: Array[ShopItem] = []
var upgrades: Array[ShopItem] = []
var equipment: Array[ShopItem] = []
var special_items: Array[ShopItem] = []

# Player's inventory (for consumables quantity tracking)
var inventory: Dictionary = {}  # item_id -> quantity

# Permanent upgrades purchased
var permanent_upgrades: Dictionary = {}  # stat_type -> total_value

# Equipment equipped
var equipped_items: Dictionary = {}  # slot -> item


@export_file("*.json") var items_json_path: String = "res://resources/data/shop_items.json"

func _ready():
	_initialize_shop_items()


func notify_shop_opened() -> void:
	shop_opened.emit()


func notify_shop_closed() -> void:
	shop_closed.emit()


func _initialize_shop_items():
	var file = FileAccess.open(items_json_path, FileAccess.READ)
	if file == null:
		push_error("[ShopManager] Failed to open items JSON: %s" % items_json_path)
		return
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("[ShopManager] Failed to parse items JSON: %s" % json.get_error_message())
		return
	var data = json.data
	if data == null:
		push_error("[ShopManager] Items JSON parsed to null")
		return
	
	# Load items from each category
	_load_category(data, "consumables", consumables)
	_load_category(data, "upgrades", upgrades)
	_load_category(data, "equipment", equipment)
	_load_category(data, "special", special_items)
	
	# Combine all
	for item in consumables:
		all_items.append(item)
	for item in upgrades:
		all_items.append(item)
	for item in equipment:
		all_items.append(item)
	for item in special_items:
		all_items.append(item)


func _load_category(data: Dictionary, category_key: String, target_array: Array[ShopItem]) -> void:
	var items_array = data.get(category_key, [])
	for item_data in items_array:
		var item = _item_from_dict(item_data)
		if item != null:
			target_array.append(item)


func _item_from_dict(d: Dictionary) -> ShopItem:
	var item = ShopItem.new()
	item.item_id = str(d.get("item_id", ""))
	item.display_name = str(d.get("display_name", "Item"))
	item.description = str(d.get("description", ""))
	item.item_type = _parse_item_type(str(d.get("item_type", "CONSUMABLE")))
	item.price = int(d.get("price", 10))
	item.max_stacks = int(d.get("max_stacks", 99))
	item.stat_type = _parse_stat_type(str(d.get("stat_type", "NONE")))
	item.stat_value = float(d.get("stat_value", 0.0))
	item.is_percentage = bool(d.get("is_percentage", false))
	item.duration = float(d.get("duration", 0.0))
	item.instant_heal = int(d.get("instant_heal", 0))
	item.equipment_slot = str(d.get("equipment_slot", ""))
	item.restricted_to_class = str(d.get("restricted_to_class", ""))
	return item


func _parse_item_type(type_str: String) -> ShopItem.ItemType:
	match type_str:
		"CONSUMABLE": return ShopItem.ItemType.CONSUMABLE
		"PERMANENT_UPGRADE": return ShopItem.ItemType.PERMANENT_UPGRADE
		"EQUIPMENT": return ShopItem.ItemType.EQUIPMENT
		"SPECIAL": return ShopItem.ItemType.SPECIAL
		_: return ShopItem.ItemType.CONSUMABLE


func _parse_stat_type(stat_str: String) -> ShopItem.StatType:
	match stat_str:
		"NONE": return ShopItem.StatType.NONE
		"MAX_HP": return ShopItem.StatType.MAX_HP
		"ATTACK": return ShopItem.StatType.ATTACK
		"SPEED": return ShopItem.StatType.SPEED
		"DEFENSE": return ShopItem.StatType.DEFENSE
		"CRIT_CHANCE": return ShopItem.StatType.CRIT_CHANCE
		"CRIT_DAMAGE": return ShopItem.StatType.CRIT_DAMAGE
		"LIFESTEAL": return ShopItem.StatType.LIFESTEAL
		"DODGE_CHANCE": return ShopItem.StatType.DODGE_CHANCE
		"COIN_BOOST": return ShopItem.StatType.COIN_BOOST
		"XP_BOOST": return ShopItem.StatType.XP_BOOST
		"ABILITY_COOLDOWN": return ShopItem.StatType.ABILITY_COOLDOWN
		_: return ShopItem.StatType.NONE


# === PURCHASE LOGIC ===

func purchase_item(item: ShopItem) -> bool:
	if not item.can_afford(CoinManager.get_coins()):
		item_purchased.emit(item, false)
		return false
	
	# Spend coins
	CoinManager.spend_coins(item.price)
	
	# Apply item effect
	_apply_item(item)
	
	# Track purchase
	match item.item_type:
		ShopItem.ItemType.CONSUMABLE:
			if not inventory.has(item.item_id):
				inventory[item.item_id] = 0
			inventory[item.item_id] += 1
			item.quantity = inventory[item.item_id]
		
		ShopItem.ItemType.PERMANENT_UPGRADE:
			item.owned = true
			# Track permanent stat
			var stat_key = item.stat_type
			if not permanent_upgrades.has(stat_key):
				permanent_upgrades[str(stat_key)] = 0.0
			permanent_upgrades[str(stat_key)] += item.stat_value
		
		ShopItem.ItemType.EQUIPMENT:
			item.owned = true
			equipped_items[item.equipment_slot] = item
		
		ShopItem.ItemType.SPECIAL:
			if not inventory.has(item.item_id):
				inventory[item.item_id] = 0
			inventory[item.item_id] += 1
			item.quantity = inventory[item.item_id]
	
	item_purchased.emit(item, true)
	return true


func _apply_item(item: ShopItem):
	# Find player
	var player = _get_local_player()
	if player == null:
		return
	
	# Instant heal
	if item.instant_heal > 0:
		if player.has_node("Health"):
			player.health.heal(item.instant_heal)
		DamageNumbers.spawn_heal(player.global_position, item.instant_heal)
		return
	
	# XP Tome
	if item.item_id == "xp_tome":
		if player != null:
			LevelSystem.add_xp(player, 50)
		return
	
	# Permanent stat upgrades
	if item.item_type == ShopItem.ItemType.PERMANENT_UPGRADE:
		_apply_permanent_stat(player, item)
		return
	
	# Equipment
	if item.item_type == ShopItem.ItemType.EQUIPMENT:
		_apply_equipment(player, item)
		return
	
	# Temporary buffs (potions)
	if item.duration > 0:
		_apply_temporary_buff(player, item)
		return


func _apply_permanent_stat(player: Node, item: ShopItem):
	match item.stat_type:
		ShopItem.StatType.MAX_HP:
			if player.has_node("Health"):
				player.health.max_health += int(item.stat_value)
				player.health.current_health += int(item.stat_value)
		ShopItem.StatType.ATTACK:
			player.attack_damage += int(item.stat_value)
		ShopItem.StatType.SPEED:
			if item.is_percentage:
				player.speed *= 1.0 + (item.stat_value / 100.0)
			else:
				player.speed += item.stat_value
		ShopItem.StatType.CRIT_CHANCE:
			var current = player.get_meta("crit_chance", 0.0)
			player.set_meta("crit_chance", current + item.stat_value / 100.0)
		ShopItem.StatType.LIFESTEAL:
			var current = player.get_meta("lifesteal", 0.0)
			player.set_meta("lifesteal", current + item.stat_value / 100.0)
		ShopItem.StatType.COIN_BOOST:
			CoinManager.drop_chance = min(CoinManager.drop_chance + item.stat_value / 100.0, 1.0)


func _apply_equipment(player: Node, item: ShopItem):
	match item.stat_type:
		ShopItem.StatType.ATTACK:
			player.attack_damage += int(item.stat_value)
		ShopItem.StatType.SPEED:
			if item.is_percentage:
				player.speed *= 1.0 + (item.stat_value / 100.0)
		ShopItem.StatType.CRIT_CHANCE:
			var current = player.get_meta("crit_chance", 0.0)
			player.set_meta("crit_chance", current + item.stat_value / 100.0)


func _apply_temporary_buff(player: Node, item: ShopItem):
	match item.stat_type:
		ShopItem.StatType.DEFENSE:
			var current = player.get_meta("defense_modifier", 1.0)
			player.set_meta("defense_modifier", current * (1.0 + item.stat_value / 100.0))
			# Schedule removal
			await get_tree().create_timer(item.duration).timeout
			if is_instance_valid(player):
				player.set_meta("defense_modifier", current)
		
		ShopItem.StatType.SPEED:
			var base_speed = player.speed
			player.speed *= (1.0 + item.stat_value / 100.0)
			await get_tree().create_timer(item.duration).timeout
			if is_instance_valid(player):
				player.speed = base_speed


func _get_local_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.is_local_player:
			return player
	return null


func get_item_by_id(item_id: String) -> ShopItem:
	for item in all_items:
		if item.item_id == item_id:
			return item
	return null


func get_inventory_quantity(item_id: String) -> int:
	return inventory.get(item_id, 0)


func has_revive_stone() -> bool:
	return inventory.get("revive_stone", 0) > 0


func use_revive_stone() -> bool:
	if has_revive_stone():
		inventory["revive_stone"] -= 1
		return true
	return false


func get_total_stat_bonus(stat_type: ShopItem.StatType) -> float:
	return permanent_upgrades.get(str(stat_type), 0.0)
