extends Node

## CoinManager - Singleton for managing player coins
## Add to AutoLoad as "CoinManager"

signal coins_changed(total: int)

var total_coins: int = 0

@export var coin_scene: PackedScene

# Coin drop settings
var drop_chance: float = 0.5  # 50% chance, can be modified by upgrades
const BASE_COIN_VALUE: int = 1
const MAX_COIN_VALUE: int = 5


func _ready():
	_ensure_coin_scene_loaded()
	# Load saved coins if any
	_load_coins()


func add_coins(amount: int) -> void:
	total_coins += amount
	coins_changed.emit(total_coins)
	print("[CoinManager] Collected %d coins. Total: %d" % [amount, total_coins])


func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		coins_changed.emit(total_coins)
		return true
	return false


func get_coins() -> int:
	return total_coins


func reset_coins() -> void:
	total_coins = 0
	coins_changed.emit(total_coins)


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


func _load_coins():
	# TODO: Implement save/load with file
	# For now, start at 0
	total_coins = 0


func save_coins():
	# TODO: Implement save to file
	pass


func _ensure_coin_scene_loaded() -> bool:
	if coin_scene != null:
		return true

	push_error("[CoinManager] coin_scene is not assigned.")
	return false
