extends Node

# Admin Manager - manages admin privileges and tools
# Add this as an autoload singleton

signal admin_mode_changed(enabled: bool)

const ADMIN_FILE_PATH := "res://config/admin_list.cfg"

var _is_admin: bool = false
var _admin_level: int = 0  # 0=none, 1=moderator, 2=admin, 3=super admin
var _admin_tools_visible: bool = false

# Admin user IDs (set via config or hardcoded)
var _admin_user_ids: Array[String] = []
var _admin_passwords: Dictionary = {}

# Settings
@export var enable_admin_tools: bool = true
@export var require_password: bool = true
@export var admin_password: String = "admin123"


func _ready() -> void:
	_load_admin_config()


func _load_admin_config() -> void:
	var config := ConfigFile.new()
	if config.load(ADMIN_FILE_PATH) == OK:
		var ids: Array = config.get_value("admins", "user_ids", [])
		for id in ids:
			_admin_user_ids.append(str(id))
		# Load passwords if section exists
		if config.has_section("passwords"):
			var password_keys: PackedStringArray = config.get_section_keys("passwords")
			for key in password_keys:
				_admin_passwords[key] = config.get_value("passwords", key, "")


func is_admin() -> bool:
	return _is_admin


func get_admin_level() -> int:
	return _admin_level


func check_admin_status(user_id: String) -> bool:
	if not enable_admin_tools:
		return false
	
	# Check if user ID is in admin list
	if user_id in _admin_user_ids:
		_is_admin = true
		_admin_level = 2
		return true
	
	# Check session metadata for admin flag
	if MultiplayerManager.session != null:
		var meta = MultiplayerManager.session.vars
		if meta != null and meta.get("is_admin", false):
			_is_admin = true
			_admin_level = meta.get("admin_level", 1)
			return true
	
	return false


func authenticate_admin(password: String) -> bool:
	if not require_password:
		return true
	
	if password == admin_password:
		_is_admin = true
		_admin_level = 2
		return true
	
	return false


func set_admin_mode(enabled: bool) -> void:
	_admin_tools_visible = enabled
	admin_mode_changed.emit(enabled)


func are_tools_visible() -> bool:
	return _admin_tools_visible and _is_admin


# Admin Actions - these send special match state messages
func admin_kick_player(user_id: String, reason: String = "") -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "kick",
		"target_user_id": user_id,
		"reason": reason
	})


func admin_ban_player(user_id: String, reason: String = "") -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "ban",
		"target_user_id": user_id,
		"reason": reason
	})


func admin_broadcast_message(message: String) -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_broadcast",
		"message": message,
		"sender": "ADMIN"
	})


func admin_force_start_game() -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "force_start"
	})


func admin_change_host(new_host_id: String) -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "change_host",
		"target_user_id": new_host_id
	})


func admin_set_lobby_name(new_name: String) -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "lobby_name",
		"name": new_name
	})


func admin_close_lobby(reason: String = "") -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "close_lobby",
		"reason": reason
	})


func admin_teleport_player(user_id: String, x: float, y: float) -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "teleport",
		"target_user_id": user_id,
		"x": x,
		"y": y
	})


func admin_give_item(user_id: String, item_id: String, amount: int = 1) -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "give_item",
		"target_user_id": user_id,
		"item_id": item_id,
		"amount": amount
	})


func admin_set_player_stat(user_id: String, stat_name: String, value: float) -> void:
	if not _is_admin:
		return
	MultiplayerManager.send_match_state({
		"type": "admin_action",
		"action": "set_stat",
		"target_user_id": user_id,
		"stat": stat_name,
		"value": value
	})
