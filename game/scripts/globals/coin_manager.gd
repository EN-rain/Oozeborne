extends Node

## CoinManager - Singleton for managing player coins
## Add to AutoLoad as "CoinManager"

signal coins_changed(total: int)

var total_coins: int = 0
var _coin_totals_by_user: Dictionary = {}

@export var coin_scene: PackedScene

# Coin drop settings
var drop_chance: float = 0.5  # 50% chance, can be modified by upgrades
const BASE_COIN_VALUE: int = 1
const MAX_COIN_VALUE: int = 5


func _ready():
	_ensure_coin_scene_loaded()
	# Load saved coins if any
	_load_coins()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		save_coins()


func add_coins(amount: int, user_id: String = "") -> void:
	var target_user_id := _resolve_coin_user_id(user_id)
	var previous_local_total := get_coins()
	_coin_totals_by_user[target_user_id] = get_coins(target_user_id) + amount
	_sync_legacy_total()
	if get_coins() != previous_local_total:
		coins_changed.emit(get_coins())
		save_coins()


func spend_coins(amount: int, user_id: String = "") -> bool:
	var target_user_id := _resolve_coin_user_id(user_id)
	if get_coins(target_user_id) >= amount:
		var previous_local_total := get_coins()
		_coin_totals_by_user[target_user_id] = get_coins(target_user_id) - amount
		_sync_legacy_total()
		if get_coins() != previous_local_total:
			coins_changed.emit(get_coins())
			save_coins()
		return true
	return false


func get_coins(user_id: String = "") -> int:
	var target_user_id := _resolve_coin_user_id(user_id)
	return int(_coin_totals_by_user.get(target_user_id, 0))


func set_coins(amount: int, user_id: String = "") -> void:
	var target_user_id := _resolve_coin_user_id(user_id)
	var previous_local_total := get_coins()
	_coin_totals_by_user[target_user_id] = maxi(0, amount)
	_sync_legacy_total()
	if get_coins() != previous_local_total:
		coins_changed.emit(get_coins())
		save_coins()


func reset_coins(user_id: String = "") -> void:
	var target_user_id := _resolve_coin_user_id(user_id)
	var previous_local_total := get_coins()
	_coin_totals_by_user[target_user_id] = 0
	_sync_legacy_total()
	if get_coins() != previous_local_total:
		coins_changed.emit(get_coins())


## Spawn coin drops at position with 50% chance
func try_spawn_coin_drop(at_position: Vector2, enemy_xp_value: int = 10) -> void:
	if randf() > drop_chance:
		return  # No drop this time
	
	# Coin value scales with enemy XP value
	var coin_value = clampi(1 + int(enemy_xp_value / 20.0), BASE_COIN_VALUE, MAX_COIN_VALUE)
	
	# Spawn the coin
	if not _ensure_coin_scene_loaded():
		push_error("[CoinManager] Failed to load coin scene")
		return
	var coin = coin_scene.instantiate()
	
	# Set position with slight random offset
	var spawn_pos = at_position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	coin.setup(coin_value, spawn_pos)
	var host := get_tree().current_scene
	if host == null:
		push_error("[CoinManager] No current scene available for coin drop")
		return
	host.call_deferred("add_child", coin)


## Spawn multiple coins (for special drops)
func spawn_coin_burst(at_position: Vector2, count: int = 3, value_per_coin: int = 1) -> void:
	for i in range(count):
		if not _ensure_coin_scene_loaded():
			push_error("[CoinManager] Failed to load coin scene")
			return
		var coin = coin_scene.instantiate()
		
		var angle = randf() * TAU
		var dist = randf_range(20, 50)
		var spawn_pos = at_position + Vector2(cos(angle), sin(angle)) * dist
		coin.setup(value_per_coin, spawn_pos)
		var host := get_tree().current_scene
		if host == null:
			push_error("[CoinManager] No current scene available for coin burst")
			return
		host.call_deferred("add_child", coin)


const SAVE_PATH := "user://coins.sav"


func _load_coins():
	if not FileAccess.file_exists(SAVE_PATH):
		_coin_totals_by_user.clear()
		_coin_totals_by_user[_resolve_coin_user_id()] = 0
		_sync_legacy_total()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("[CoinManager] Failed to open coin save file for reading")
		_coin_totals_by_user.clear()
		_coin_totals_by_user[_resolve_coin_user_id()] = 0
		_sync_legacy_total()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		push_warning("[CoinManager] Invalid coin save format, resetting")
		_coin_totals_by_user.clear()
		_coin_totals_by_user[_resolve_coin_user_id()] = 0
		_sync_legacy_total()
		return
	_coin_totals_by_user.clear()
	for key in parsed:
		_coin_totals_by_user[str(key)] = int(parsed[key])
	_sync_legacy_total()


func save_coins():
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[CoinManager] Failed to open coin save file for writing")
		return
	var data := {}
	for key in _coin_totals_by_user:
		data[str(key)] = int(_coin_totals_by_user[key])
	file.store_string(JSON.stringify(data))
	file.close()


func _ensure_coin_scene_loaded() -> bool:
	if coin_scene != null:
		return true

	push_error("[CoinManager] coin_scene is not assigned.")
	return false


func get_player_coin_user_id(body: Node = null) -> String:
	if body != null and body.has_meta("network_user_id"):
		return str(body.get_meta("network_user_id"))
	if body != null and "is_local_player" in body and body.is_local_player:
		return _resolve_coin_user_id()
	return _resolve_coin_user_id()


func _resolve_coin_user_id(user_id: String = "") -> String:
	var trimmed_user_id := user_id.strip_edges()
	if not trimmed_user_id.is_empty():
		return trimmed_user_id
	if MultiplayerManager != null and MultiplayerManager.session != null:
		var session_user_id := str(MultiplayerManager.session.user_id)
		if not session_user_id.is_empty():
			return session_user_id
	return "solo"


func _sync_legacy_total() -> void:
	total_coins = get_coins()
