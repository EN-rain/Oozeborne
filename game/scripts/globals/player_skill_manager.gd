extends Node

## PlayerSkillManager - Centralized local skill input and cooldown handling.
## Owns the readiness logic for the player's basic attack and dash.

var _local_player: Node = null
var _basic_attack_ready_at_sec: float = 0.0
var _dash_ready_at_sec: float = 0.0
var _ability_slots: Dictionary = {}
var _ability_ready_at_sec: Dictionary = {}


func bind_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	_local_player = player
	_basic_attack_ready_at_sec = 0.0
	_dash_ready_at_sec = 0.0
	_ability_slots.clear()
	_ability_ready_at_sec.clear()
	if "can_basic_attack" in player:
		player.can_basic_attack = true
	if "can_dash" in player:
		player.can_dash = true


func unbind_player(player: Node) -> void:
	if player != null and player == _local_player:
		_local_player = null
		_basic_attack_ready_at_sec = 0.0
		_dash_ready_at_sec = 0.0
		_ability_slots.clear()
		_ability_ready_at_sec.clear()


func process_local_input(player: Node, input_dir: Vector2) -> void:
	if player == null or not is_instance_valid(player):
		return
	if _local_player != player:
		bind_player(player)
	if not ("is_local_player" in player and player.is_local_player):
		return
	
	if Input.is_action_just_pressed("dash"):
		request_dash(player, input_dir)
	
	if Input.is_action_just_pressed("basic_attack"):
		request_basic_attack(player)


func request_basic_attack(player: Node) -> bool:
	if not _can_use_basic_attack(player):
		return false
	
	if "can_basic_attack" in player:
		player.can_basic_attack = false
	_basic_attack_ready_at_sec = _get_now_sec() + _get_basic_attack_cooldown(player)
	player.perform_basic_attack()
	return true


func request_dash(player: Node, direction: Vector2) -> bool:
	if not _can_use_dash(player):
		return false
	
	if "can_dash" in player:
		player.can_dash = false
	_dash_ready_at_sec = _get_now_sec() + _get_dash_cooldown(player)
	player.perform_dash(direction)
	return true


func get_basic_attack_cooldown_remaining(player: Node) -> float:
	if player == null or player != _local_player:
		return 0.0
	_refresh_ready_flags(player)
	return maxf(_basic_attack_ready_at_sec - _get_now_sec(), 0.0)


func get_dash_cooldown_remaining(player: Node) -> float:
	if player == null or player != _local_player:
		return 0.0
	_refresh_ready_flags(player)
	return maxf(_dash_ready_at_sec - _get_now_sec(), 0.0)


func register_ability_slot(slot_index: int, skill_id: String, cooldown: float) -> void:
	if slot_index < 0:
		return
	_ability_slots[slot_index] = {
		"skill_id": skill_id,
		"cooldown": maxf(cooldown, 0.0),
	}
	if not _ability_ready_at_sec.has(slot_index):
		_ability_ready_at_sec[slot_index] = 0.0


func clear_ability_slot(slot_index: int) -> void:
	_ability_slots.erase(slot_index)
	_ability_ready_at_sec.erase(slot_index)


func request_ability(slot_index: int, player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if not _ability_slots.has(slot_index):
		return false
	var slot_data: Dictionary = _ability_slots[slot_index]
	var now := _get_now_sec()
	var ready_at := float(_ability_ready_at_sec.get(slot_index, 0.0))
	if now < ready_at:
		return false
	_ability_ready_at_sec[slot_index] = now + float(slot_data.get("cooldown", 0.0))
	var skill_id := str(slot_data.get("skill_id", ""))
	if player.has_method("perform_skill_ability"):
		player.perform_skill_ability(skill_id)
	elif player.has_method("use_slotted_skill"):
		player.use_slotted_skill(skill_id)
	return true


func get_ability_cooldown_remaining(slot_index: int) -> float:
	if not _ability_slots.has(slot_index):
		return 0.0
	return maxf(float(_ability_ready_at_sec.get(slot_index, 0.0)) - _get_now_sec(), 0.0)


func _can_use_basic_attack(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if "is_taking_damage" in player and player.is_taking_damage:
		return false
	if "is_dashing" in player and player.is_dashing:
		return false
	_refresh_ready_flags(player)
	return "can_basic_attack" in player and player.can_basic_attack


func _can_use_dash(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if "is_dashing" in player and player.is_dashing:
		return false
	if "is_taking_damage" in player and player.is_taking_damage:
		return false
	_refresh_ready_flags(player)
	return "can_dash" in player and player.can_dash


func _get_basic_attack_cooldown(player: Node) -> float:
	if player != null and "basic_attack_cooldown" in player:
		return maxf(float(player.basic_attack_cooldown), 0.0)
	return 0.0


func _get_dash_cooldown(player: Node) -> float:
	if player != null and "dash_cooldown" in player:
		return maxf(float(player.dash_cooldown), 0.0)
	return 0.0


func _get_now_sec() -> float:
	return Time.get_ticks_msec() / 1000.0


func _refresh_ready_flags(player: Node) -> void:
	var now_sec: float = _get_now_sec()
	if "can_basic_attack" in player and now_sec >= _basic_attack_ready_at_sec:
		player.can_basic_attack = true
	if "can_dash" in player and now_sec >= _dash_ready_at_sec:
		player.can_dash = true
