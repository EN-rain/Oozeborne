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


func _ready():
	_initialize_shop_items()


func notify_shop_opened() -> void:
	shop_opened.emit()


func notify_shop_closed() -> void:
	shop_closed.emit()


func _initialize_shop_items():
	# === CONSUMABLES ===
	_register_item(_create_health_potion_small(), consumables)
	_register_item(_create_health_potion_large(), consumables)
	_register_item(_create_shield_potion(), consumables)
	_register_item(_create_speed_potion(), consumables)
	_register_item(_create_iron_skin_potion(), consumables)
	
	# === PERMANENT UPGRADES ===
	_register_item(_create_max_hp_10(), upgrades)
	_register_item(_create_max_hp_25(), upgrades)
	_register_item(_create_attack_5(), upgrades)
	_register_item(_create_speed_5(), upgrades)
	_register_item(_create_crit_5(), upgrades)
	_register_item(_create_lifesteal_3(), upgrades)
	
	# === EQUIPMENT ===
	_register_item(_create_iron_sword(), equipment)
	_register_item(_create_swift_boots(), equipment)
	_register_item(_create_warrior_ring(), equipment)
	_register_item(_create_assassin_dagger(), equipment)
	
	# === SPECIAL ===
	_register_item(_create_revive_stone(), special_items)
	_register_item(_create_xp_tome(), special_items)
	_register_item(_create_gold_booster(), special_items)
	_register_item(_create_magnet_ring(), special_items)
	
	# Combine all
	for item in consumables:
		all_items.append(item)
	for item in upgrades:
		all_items.append(item)
	for item in equipment:
		all_items.append(item)
	for item in special_items:
		all_items.append(item)


func _register_item(item: ShopItem, category: Array):
	category.append(item)


# === ITEM FACTORIES ===

func _create_health_potion_small() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "health_potion_small"
	item.display_name = "Health Potion"
	item.description = "A small red potion that restores health."
	item.item_type = ShopItem.ItemType.CONSUMABLE
	item.price = 8
	item.max_stacks = 99
	item.instant_heal = 50
	return item


func _create_health_potion_large() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "health_potion_large"
	item.display_name = "Large Health Potion"
	item.description = "A potent red potion that restores significant health."
	item.item_type = ShopItem.ItemType.CONSUMABLE
	item.price = 20
	item.max_stacks = 99
	item.instant_heal = 100
	return item


func _create_shield_potion() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "shield_potion"
	item.display_name = "Shield Potion"
	item.description = "Grants temporary damage resistance."
	item.item_type = ShopItem.ItemType.CONSUMABLE
	item.price = 25
	item.max_stacks = 20
	item.stat_type = ShopItem.StatType.DEFENSE
	item.stat_value = 50.0
	item.is_percentage = true
	item.duration = 30.0
	return item


func _create_speed_potion() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "speed_potion"
	item.display_name = "Speed Potion"
	item.description = "Grants temporary movement speed boost."
	item.item_type = ShopItem.ItemType.CONSUMABLE
	item.price = 15
	item.max_stacks = 20
	item.stat_type = ShopItem.StatType.SPEED
	item.stat_value = 30.0
	item.is_percentage = true
	item.duration = 60.0
	return item


func _create_iron_skin_potion() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "iron_skin_potion"
	item.display_name = "Iron Skin Potion"
	item.description = "Grants knockback immunity."
	item.item_type = ShopItem.ItemType.CONSUMABLE
	item.price = 35
	item.max_stacks = 10
	return item  # Special effect handled separately


func _create_max_hp_10() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "max_hp_10"
	item.display_name = "Max HP +10"
	item.description = "Permanently increases maximum health."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 40
	item.stat_type = ShopItem.StatType.MAX_HP
	item.stat_value = 10.0
	return item


func _create_max_hp_25() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "max_hp_25"
	item.display_name = "Max HP +25"
	item.description = "Permanently increases maximum health."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 85
	item.stat_type = ShopItem.StatType.MAX_HP
	item.stat_value = 25.0
	return item


func _create_attack_5() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "attack_5"
	item.display_name = "Attack +5"
	item.description = "Permanently increases base damage."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 50
	item.stat_type = ShopItem.StatType.ATTACK
	item.stat_value = 5.0
	return item


func _create_speed_5() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "speed_5"
	item.display_name = "Speed +5%"
	item.description = "Permanently increases movement speed."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 35
	item.stat_type = ShopItem.StatType.SPEED
	item.stat_value = 5.0
	item.is_percentage = true
	return item


func _create_crit_5() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "crit_5"
	item.display_name = "Crit Chance +5%"
	item.description = "Permanently increases critical hit chance."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 70
	item.stat_type = ShopItem.StatType.CRIT_CHANCE
	item.stat_value = 5.0
	item.is_percentage = true
	return item


func _create_lifesteal_3() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "lifesteal_3"
	item.display_name = "Lifesteal +3%"
	item.description = "Permanently increases lifesteal."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 90
	item.stat_type = ShopItem.StatType.LIFESTEAL
	item.stat_value = 3.0
	item.is_percentage = true
	return item


func _create_iron_sword() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "iron_sword"
	item.display_name = "Iron Sword"
	item.description = "A sturdy iron sword that increases damage."
	item.item_type = ShopItem.ItemType.EQUIPMENT
	item.price = 65
	item.stat_type = ShopItem.StatType.ATTACK
	item.stat_value = 10.0
	item.equipment_slot = "weapon"
	return item


func _create_swift_boots() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "swift_boots"
	item.display_name = "Swift Boots"
	item.description = "Lightweight boots that increase speed."
	item.item_type = ShopItem.ItemType.EQUIPMENT
	item.price = 50
	item.stat_type = ShopItem.StatType.SPEED
	item.stat_value = 15.0
	item.is_percentage = true
	item.equipment_slot = "boots"
	return item


func _create_warrior_ring() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "warrior_ring"
	item.display_name = "Warrior's Ring"
	item.description = "A ring that boosts damage but slows movement."
	item.item_type = ShopItem.ItemType.EQUIPMENT
	item.price = 100
	item.stat_type = ShopItem.StatType.ATTACK
	item.stat_value = 15.0
	item.equipment_slot = "ring"
	return item


func _create_assassin_dagger() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "assassin_dagger"
	item.display_name = "Assassin's Dagger"
	item.description = "A deadly dagger that boosts critical hits."
	item.item_type = ShopItem.ItemType.EQUIPMENT
	item.price = 85
	item.stat_type = ShopItem.StatType.CRIT_CHANCE
	item.stat_value = 10.0
	item.is_percentage = true
	item.equipment_slot = "weapon"
	return item


func _create_revive_stone() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "revive_stone"
	item.display_name = "Revive Stone"
	item.description = "Automatically revive with 50% HP on death. One use."
	item.item_type = ShopItem.ItemType.SPECIAL
	item.price = 180
	item.max_stacks = 1
	return item


func _create_xp_tome() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "xp_tome"
	item.display_name = "XP Tome"
	item.description = "Instantly gain 50 XP."
	item.item_type = ShopItem.ItemType.SPECIAL
	item.price = 25
	item.max_stacks = 10
	return item


func _create_gold_booster() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "gold_booster"
	item.display_name = "Gold Booster"
	item.description = "Permanently increases coin drop rate."
	item.item_type = ShopItem.ItemType.PERMANENT_UPGRADE
	item.price = 130
	item.stat_type = ShopItem.StatType.COIN_BOOST
	item.stat_value = 25.0
	item.is_percentage = true
	return item


func _create_magnet_ring() -> ShopItem:
	var item = ShopItem.new()
	item.item_id = "magnet_ring"
	item.display_name = "Magnet Ring"
	item.description = "Increases coin attraction range."
	item.item_type = ShopItem.ItemType.SPECIAL
	item.price = 45
	item.stat_type = ShopItem.StatType.NONE
	item.max_stacks = 1
	return item


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
