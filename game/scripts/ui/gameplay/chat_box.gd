extends Control

## ChatBox - In-game chat UI
## Supports regular chat messages and admin commands

signal chat_message_sent(message: String)

const MAX_MESSAGES := 50
const CHAT_PREFIX := "[color=white]"
const SYSTEM_PREFIX := "[color=#ffff00]"
const ADMIN_PREFIX := "[color=#ff6666]"
const PARTY_LEADER_PREFIX := "[color=#66ff66]"

@onready var messages_label: RichTextLabel = %Messages
@onready var input_field: LineEdit = %Input
@onready var send_button: Button = %SendButton

var _message_history: Array[String] = []

func _ready() -> void:
	hide()
	if input_field != null:
		input_field.focus_entered.connect(_on_input_focus_entered)
		input_field.focus_exited.connect(_on_input_focus_exited)

func _on_input_submitted(text: String) -> void:
	if text.is_empty():
		return
	_send_message(text.strip_edges())
	input_field.clear()

func _on_send_pressed() -> void:
	if input_field != null:
		_on_input_submitted(input_field.text)

func _send_message(message: String) -> void:
	if message.is_empty():
		return
	
	# Check for commands (admin or party leader)
	if message.begins_with("/"):
		_process_command(message)
		return
	
	# Regular chat message
	chat_message_sent.emit(message)
	_add_message(MultiplayerManager.player_ign, message, false)

func _process_command(message: String) -> void:
	var parts := message.split(" ", false, 1)
	if parts.is_empty():
		return
	
	var command := parts[0].to_lower()
	var args := parts[1] if parts.size() > 1 else ""
	
	# Commands available to everyone
	match command:
		"/help":
			_show_help()
			return
		"/ping":
			var ping_ms := int(MultiplayerUtils.get_ping() * 1000)
			_add_system_message("Ping: %d ms" % ping_ms)
			return
	
	# Admin-only commands - silently ignore for non-admins
	if not MultiplayerManager.is_admin:
		return
	
	_process_admin_command(command, args)

func _process_admin_command(command: String, args: String) -> void:
	match command:
		"/help":
			_add_system_message("Admin commands: /spawn <mob> [count], /add coins <amount>, /add level <amount>, /setlevel <1-100>, /killall, /pause, /resume, /help, /ping")
		"/setlevel":
			var level := args.to_int()
			if level > 0 and level <= 100:
				var player := get_tree().get_first_node_in_group("player")
				if player != null:
					LevelSystem.set_level(player, level)
					_add_admin_message("Set level to %d" % level)
			else:
				_add_system_message("Invalid level (1-100)")
		"/add":
			_process_add_command(args)
		"/spawn":
			_process_spawn_command(args)
		"/killall":
			var mobs := get_tree().get_nodes_in_group("mobs")
			for mob in mobs:
				if mob.has_method("die"):
					mob.die()
			_add_admin_message("Killed all mobs")
		"/pause":
			get_tree().paused = true
			_add_admin_message("Game paused")
		"/resume":
			get_tree().paused = false
			_add_admin_message("Game resumed")
		_:
			_add_system_message("Unknown admin command: %s" % command)


func _process_spawn_command(args: String) -> void:
	# /spawn <mob_name> [count]
	# e.g. /spawn archer 3
	var parts := args.split(" ", false)
	if parts.is_empty():
		_add_system_message("Usage: /spawn <mob_name> [count]")
		_add_system_message("Mobs: slime, lancer, archer, warden, boss")
		return
	var mob_name := parts[0]
	var count := parts[1].to_int() if parts.size() > 1 else 1
	if count <= 0:
		count = 1
	var mob_spawner := get_tree().get_first_node_in_group("mob_spawner")
	if mob_spawner != null and mob_spawner.has_method("spawn_mob_by_name"):
		var spawned: int = mob_spawner.spawn_mob_by_name(mob_name, count)
		if spawned > 0:
			_add_admin_message("Spawned %d %s(s)" % [spawned, mob_name])
		else:
			_add_system_message("Unknown mob: %s. Available: slime, lancer, archer, warden, boss" % mob_name)
	else:
		_add_system_message("Mob spawner not found")


func _process_add_command(args: String) -> void:
	# /add coins <amount>  - add coins
	# /add level <amount>  - add levels (current + amount)
	var parts := args.split(" ", false)
	if parts.size() < 2:
		_add_system_message("Usage: /add coins <amount> or /add level <amount>")
		return
	var sub_cmd := parts[0].to_lower()
	var amount := parts[1].to_int()
	if amount <= 0:
		_add_system_message("Invalid amount")
		return
	match sub_cmd:
		"coins":
			CoinManager.add_coins(amount)
			_add_admin_message("Added %d coins (total: %d)" % [amount, CoinManager.get_coins()])
		"level":
			var player := get_tree().get_first_node_in_group("player")
			if player != null:
				var current_level := LevelSystem.get_level(player)
				var new_level := mini(current_level + amount, 100)
				LevelSystem.set_level(player, new_level)
				_add_admin_message("Added %d levels (%d -> %d)" % [amount, current_level, new_level])
			else:
				_add_system_message("Player not found")
		_:
			_add_system_message("Usage: /add coins <amount> or /add level <amount>")


func _process_party_leader_command(command: String, args: String) -> void:
	match command:
		"/help":
			_add_system_message("Leader commands: /pause, /resume, /kick <player>, /help, /ping")
		"/pause":
			get_tree().paused = true
			_add_party_leader_message("Game paused by party leader")
		"/resume":
			get_tree().paused = false
			_add_party_leader_message("Game resumed by party leader")
		"/kick":
			if args.is_empty():
				_add_system_message("Usage: /kick <player_name>")
			else:
				_kick_player(args)
		_:
			pass


func add_remote_message(sender_name: String, message: String, is_admin: bool = false, is_party_leader: bool = false) -> void:
	if is_admin:
		_add_admin_message("%s: %s" % [sender_name, message])
	elif is_party_leader:
		_add_party_leader_message("%s: %s" % [sender_name, message])
	else:
		_add_message(sender_name, message, false)


func _show_help() -> void:
	if not MultiplayerManager.is_admin:
		return
	var commands := "Admin commands: /spawn <mob> [count], /add coins <amount>, /add level <amount>, /setlevel <1-100>, /killall, /pause, /resume, /help, /ping"
	_add_system_message(commands)


func _kick_player(player_name: String) -> void:
	# Find the user_id for the given player name
	var target_id := ""
	for user_id in MultiplayerManager.players:
		var info = MultiplayerManager.players[user_id]
		if info.get("ign", "").strip_edges() == player_name.strip_edges():
			target_id = user_id
			break
	if target_id.is_empty():
		_add_system_message("Player '%s' not found" % player_name)
		return
	if target_id == MultiplayerManager.user_id:
		_add_system_message("You can't kick yourself")
		return
	# Send kick request via match state
	MultiplayerManager.send_match_state({
		"type": "kick_player",
		"target_user_id": target_id,
		"target_ign": player_name
	})
	_add_party_leader_message("Kicked %s" % player_name)


func _add_message(sender_name: String, message: String, is_system: bool = false) -> void:
	var prefix := CHAT_PREFIX
	if is_system:
		prefix = SYSTEM_PREFIX
	
	var formatted := "%s[color=#aaaaaa]%s:[/color] %s\n" % [prefix, sender_name, message]
	_append_text(formatted)


func _add_system_message(message: String) -> void:
	var formatted := "%s%s\n" % [SYSTEM_PREFIX, message]
	_append_text(formatted)


func _add_admin_message(message: String) -> void:
	var formatted := "%s[ADMIN] %s\n" % [ADMIN_PREFIX, message]
	_append_text(formatted)


func _add_party_leader_message(message: String) -> void:
	var formatted := "%s[PARTY LEADER] %s\n" % [PARTY_LEADER_PREFIX, message]
	_append_text(formatted)


func _append_text(text: String) -> void:
	if messages_label == null:
		return
	
	_message_history.append(text)
	if _message_history.size() > MAX_MESSAGES:
		_message_history.pop_front()
	
	messages_label.text = "".join(_message_history)
	messages_label.scroll_to_line(messages_label.get_line_count() - 1)


func _on_input_focus_entered() -> void:
	input_field.grab_focus()


func _on_input_focus_exited() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide()
		get_viewport().set_input_as_handled()
