extends Node2D

@onready var player = $Player
@onready var ui = $UI

@export var player_scene: PackedScene
@export var sword_slash_scene: PackedScene

var mob_spawner: Node  # MobSpawner instance

# FPS/Ping display
var _fps_label: Label
var _ping_timer: Timer

func _process(_delta):
	# Update FPS display every frame
	if _fps_label:
		var fps = Engine.get_frames_per_second()
		var ping_ms = int(MultiplayerUtils.get_ping() * 1000)
		var interp_delay = int(MultiplayerUtils.get_interpolation_delay() * 1000)
		var pending = MultiplayerUtils.get_pending_input_count()
		_fps_label.text = "FPS: %d | MS: %d | Interp: %dms | Pending: %d" % [fps, ping_ms, interp_delay, pending]

func _physics_process(delta):
	# Interpolate remote players positions in physics process to align with movement timeline
	MultiplayerUtils.interpolate_remote_players(delta)

func _ready():
	# Use room_code as seed for consistent random spawns across all clients
	if not MultiplayerManager.room_code.is_empty():
		seed(MultiplayerManager.room_code.hash())
	
	# Replace local player with class-specific scene if available
	_replace_local_player_with_class_scene()
	
	# Start near the expected authoritative spawn instead of forcing every client to the same point.
	player.global_position = Vector2(360, 300) if MultiplayerManager.is_host else Vector2(440, 300)
	
	ui.set_player(player)
	spawn_players()
	
	# Initialize mob spawner
	mob_spawner = preload("res://src/systems/game/mob_spawner.gd").new()
	mob_spawner.common_mob_scene = preload("res://scenes/entities/enemies/blue_slime.tscn")
	mob_spawner.elite_mob_lancer_scene = preload("res://scenes/entities/enemies/plagued_lancer.tscn")
	mob_spawner.elite_mob_archer_scene = preload("res://scenes/entities/enemies/archer.tscn")
	mob_spawner.initialize(self, player)
	mob_spawner.mob_spawned.connect(_on_mob_spawned)
	mob_spawner.mob_died.connect(_on_mob_died)
	add_child(mob_spawner)
	mob_spawner.spawn_initial_mobs()
	
	# Create FPS/Ping display
	_create_fps_display()
	
	# Listen for match events
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)
		if not MultiplayerManager.socket.received_match_presence.is_connected(_on_match_presence):
			MultiplayerManager.socket.received_match_presence.connect(_on_match_presence)
		# Listen for player_joined signal to spawn late joiners
		if not MultiplayerManager.player_joined.is_connected(_on_player_joined):
			MultiplayerManager.player_joined.connect(_on_player_joined)
		# Register local player for client-side prediction/reconciliation
		MultiplayerUtils.set_local_player(player)
		# Send input to authoritative server at 20Hz
		MultiplayerUtils.start_input_update_loop(player)
		# Announce our presence in game
		MultiplayerUtils.send_player_info(MultiplayerManager.player_ign, MultiplayerManager.is_host)

func _replace_local_player_with_class_scene():
	# Replace the default player with the class-specific slime scene
	var player_class: PlayerClass = MultiplayerManager.player_class
	if player_class and player_class.player_scene:
		var old_player = player
		var new_player = player_class.player_scene.instantiate()
		new_player.global_position = old_player.global_position
		new_player.name = old_player.name
		new_player.is_local_player = true
		# Copy IGN if available
		if old_player.has_method("get_ign") and new_player.has_method("set_ign"):
			new_player.set_ign(old_player.get_ign())
		old_player.queue_free()
		add_child(new_player)
		player = new_player
		print("[Main] Replaced player with class scene: ", player_class.display_name)

func _create_fps_display():
	# Create CanvasLayer for overlay
	var canvas = CanvasLayer.new()
	canvas.layer = 100  # On top of everything
	add_child(canvas)
	
	# Create FPS/Ping label
	_fps_label = Label.new()
	_fps_label.position = Vector2(DisplayServer.window_get_size().x - 150, 10)  # Top right
	_fps_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(_fps_label)
	
	# Create timer for ping updates
	_ping_timer = Timer.new()
	_ping_timer.wait_time = 1.0  # Update every second
	_ping_timer.timeout.connect(_on_ping_timeout)
	add_child(_ping_timer)
	_ping_timer.start()

func _on_ping_timeout():
	if MultiplayerManager.socket and MultiplayerManager.match_id:
		# Send ping timestamp using monotonic time
		MultiplayerManager.send_match_state({
			"type": "ping",
			"timestamp": Time.get_ticks_usec() / 1000000.0
		})

func _on_match_state(match_state):
	# Handle op codes from authoritative server
	var op_code = match_state.op_code
	var data = JSON.parse_string(match_state.data)
	
	# Op code 2 = Server state snapshot
	if op_code == MultiplayerUtils.OP_STATE:
		_handle_server_snapshot(data)
		return
	
	# Op code 3 = Player joined
	if op_code == MultiplayerUtils.OP_PLAYER_JOIN:
		_handle_player_join(data)
		return
	
	# Op code 4 = Player left
	if op_code == MultiplayerUtils.OP_PLAYER_LEAVE:
		_handle_player_leave(data)
		return
	
	# Op code 5 = Start game
	if op_code == MultiplayerUtils.OP_START_GAME:
		print("[Main] Received start_game signal while already in game")
		return
	
	# Legacy JSON-based messages (for compatibility)
	if data == null:
		print("[Main] Failed to parse match state data")
		return
	
	var sender_id = ""
	if match_state.presence != null:
		sender_id = match_state.presence.user_id
	
	match data.get("type", ""):
		"player_info":
			# Get user_id from data if sender_id is empty (broadcast echo)
			var msg_user_id = MultiplayerUtils.extract_user_id_from_data(data)
			if sender_id.is_empty() and not msg_user_id.is_empty():
				sender_id = msg_user_id
			
			if MultiplayerUtils.is_local_player(sender_id):
				return
			
			# Store player info and spawn them if not already spawned
			var ign = data.get("ign", "Unknown")
			var is_host_flag = data.get("is_host", false)
			
			# Skip if it's our own IGN
			if ign == MultiplayerManager.player_ign:
				return
			
			# Skip if still empty after trying to get from data
			if sender_id.is_empty():
				return
			
			# Add or update player - preserve presence if already stored
			if MultiplayerManager.players.has(sender_id):
				MultiplayerManager.players[sender_id]["ign"] = ign
				MultiplayerManager.players[sender_id]["is_host"] = is_host_flag
			else:
				MultiplayerManager.players[sender_id] = {"ign": ign, "is_host": is_host_flag, "presence": null}

			_apply_authoritative_player_info(sender_id, ign, is_host_flag)
			if not MultiplayerUtils.has_remote_player(sender_id):
				_spawn_player_for_user(sender_id)
		
		
		"player_attack":
			# Get user_id from data if sender_id is empty (broadcast echo)
			var msg_user_id = MultiplayerUtils.extract_user_id_from_data(data)
			if sender_id.is_empty() and not msg_user_id.is_empty():
				sender_id = msg_user_id
			
			# Handle remote player attack
			if MultiplayerUtils.is_local_player(sender_id):
				return
			
			var attack_pos = data.get("pos", {})
			var attack_rot = data.get("rot", 0.0)
			print("[Main] Received attack data: ", data, " rot: ", attack_rot)
			_spawn_remote_attack(sender_id, Vector2(attack_pos.get("x", 0), attack_pos.get("y", 0)), attack_rot)
		
		
		"ping":
			# Echo back as pong
			if match_state.presence != null:
				MultiplayerUtils.send_pong(match_state.presence.user_id, data.get("timestamp", 0))
		
		"pong":
			# Calculate ping time
			if data.get("target") == MultiplayerManager.session.user_id:
				var ping_time = MultiplayerUtils.calculate_ping(data.get("timestamp", 0.0))
				MultiplayerUtils.set_ping(ping_time)
		
		
		"request_players":
			# Someone requested player info, send ours
			MultiplayerUtils.send_player_info(MultiplayerManager.player_ign, MultiplayerManager.is_host)

func spawn_players():
	# Spawn all connected players, filtering out empty keys
	for user_id in MultiplayerManager.players:
		if not user_id.is_empty():
			_spawn_player_for_user(user_id)

func _spawn_player_for_user(user_id: String, initial_pos: Variant = null):
	# Skip empty user_id (broadcast echo)
	if user_id.is_empty():
		return
	
	# Never register local player as remote
	if user_id == MultiplayerManager.session.user_id:
		return
	
	if MultiplayerUtils.has_remote_player(user_id):
		return  # Already spawned
	
	var player_info = MultiplayerManager.players.get(user_id, {})
	var is_local = (user_id == MultiplayerManager.session.user_id)
	
	if is_local:
		# Local player already exists, just update name and IGN
		if player_info.has("ign"):
			player.name = player_info.ign
			if player.has_method("set_ign"):
				player.set_ign(player_info.ign)
	else:
		# Spawn remote player - use their class's player_scene if available
		var remote_player_class: PlayerClass = MultiplayerManager.get_player_class(user_id)
		var scene_to_use: PackedScene = remote_player_class.player_scene if remote_player_class and remote_player_class.player_scene else player_scene
		if scene_to_use == null:
			return
		var remote_player = scene_to_use.instantiate()
		var has_initial_pos := initial_pos is Vector2
		var spawn_pos: Vector2 = initial_pos if has_initial_pos else Vector2(-9999, -9999)
		remote_player.global_position = spawn_pos
		remote_player.visible = has_initial_pos
		remote_player.is_local_player = false  # Mark as remote player - this disables physics
		remote_player.velocity = Vector2.ZERO  # Reset velocity
		var remote_collision = remote_player.get_node_or_null("CollisionShape2D")
		if remote_collision:
			remote_collision.set_deferred("disabled", true)
		if player_info.has("ign"):
			remote_player.name = player_info.ign
			if remote_player.has_method("set_ign"):
				remote_player.set_ign(player_info.ign)
		add_child(remote_player)
		# Register with MultiplayerUtils for interpolation
		MultiplayerUtils.register_remote_player(user_id, remote_player, spawn_pos, has_initial_pos)
		# Add green dot indicator for this player on the minimap
		_add_player_minimap_indicator(user_id, spawn_pos)
		_apply_authoritative_player_info(user_id, player_info.get("ign", ""), player_info.get("is_host", false))

func _spawn_remote_attack(user_id: String, pos: Vector2, rotation_angle: float):
	# Spawn sword slash for remote player
	if not MultiplayerUtils.has_remote_player(user_id):
		return
	
	var player_data = MultiplayerUtils.get_remote_players()[user_id]
	var remote_player = player_data.node
	
	# Play attack animation on remote player
	if is_instance_valid(remote_player) and remote_player.has_method("play_attack_animation"):
		remote_player.play_attack_animation()
	
	_spawn_remote_slash(pos, rotation_angle)

func _spawn_remote_slash(pos: Vector2, rotation_angle: float):
	if sword_slash_scene == null:
		push_error("[Main] sword_slash_scene is NULL! Assign it in the inspector.")
		return
	var slash = sword_slash_scene.instantiate()
	print("[Main] Slash at pos: ", pos, " rotation: ", rotation_angle, " (", rad_to_deg(rotation_angle), " degrees)")
	
	# Calculate direction from rotation angle
	var dir = Vector2(cos(rotation_angle), sin(rotation_angle))
	print("[Main] Direction vector: ", dir)
	
	# Position slash in front of player (same offset as local player)
	slash.global_position = pos + dir * 12
	slash.rotation = rotation_angle
	add_child(slash)

func send_attack(pos: Vector2, rotation_angle: float):
	# Send attack to other players
	MultiplayerUtils.send_attack(pos, rotation_angle)

func _on_match_presence(presence_event):
	# Handle players joining during game
	for join in presence_event.joins:
		print("[Main] Player joined match: user_id=", join.user_id.substr(0,8))
		# Skip if this is ourselves
		if join.user_id == MultiplayerManager.session.user_id:
			continue
		if not MultiplayerManager.players.has(join.user_id):
			MultiplayerManager.players[join.user_id] = {"ign": "", "is_host": false, "presence": join}
			print("[Main] Added to players dict. Total players: ", MultiplayerManager.players.size())
			MultiplayerManager.player_joined.emit(join.user_id, "Player", false)
		else:
			MultiplayerManager.players[join.user_id]["presence"] = join
	
	# Handle players leaving
	for leave in presence_event.leaves:
		var user_id = leave.user_id
		# Skip if this is ourselves (Nakama sometimes sends our own leave event)
		if user_id == MultiplayerManager.session.user_id:
			continue
		print("[Main] Player left match: ", leave.username)
		if MultiplayerManager.players.has(user_id):
			MultiplayerManager.players.erase(user_id)
			MultiplayerManager.player_left.emit(user_id)
		if MultiplayerUtils.has_remote_player(user_id):
			var node = MultiplayerUtils.get_remote_players()[user_id].node
			if is_instance_valid(node):
				node.queue_free()
			MultiplayerUtils.unregister_remote_player(user_id)
			_remove_player_minimap_indicator(user_id)

func _add_player_minimap_indicator(user_id: String, initial_pos: Vector2):
	var player_info = MultiplayerManager.players.get(user_id, {})
	var ign = player_info.get("ign", "Unknown")
	ui.register_remote_player(user_id, ign)
	ui.update_remote_player_pos(user_id, initial_pos)

func _update_player_minimap_indicator(user_id: String, new_pos: Vector2):
	ui.update_remote_player_pos(user_id, new_pos)

func _remove_player_minimap_indicator(user_id: String):
	ui.unregister_remote_player(user_id)

func _on_mob_spawned(mob):
	ui.register_slime(mob)

func _on_mob_died(_mob, score_value: int, xp_value: int):
	ui.add_score(score_value)
	# Award XP to local player via singleton
	if player:
		LevelSystem.add_xp(player, xp_value)
		print("[Main] Awarded %d XP to player" % xp_value)

func _on_player_joined(user_id: String, username: String, _is_host: bool):
	print("[Main] Player joined signal received for: ", username)
	_spawn_player_for_user(user_id)


## Handle server state snapshot (op code 2)
func _handle_server_snapshot(data: Dictionary) -> void:
	if data == null:
		return

	var phase = str(data.get("phase", MultiplayerManager.match_phase))
	if phase != MultiplayerManager.match_phase:
		MultiplayerManager.match_phase = phase

	var players = data.get("players", [])
	for player_data in players:
		var user_id = player_data.get("user_id", "")
		if user_id.is_empty():
			continue
		
		var pos_data = player_data.get("pos", {})
		var new_pos = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
		var vel_data = player_data.get("vel", {})
		var velocity = Vector2(vel_data.get("x", 0), vel_data.get("y", 0))
		var server_seq = player_data.get("input_seq", 0)
		var facing = player_data.get("facing", 1)
		var is_attacking = player_data.get("is_attacking", false)
		var is_dashing = player_data.get("is_dashing", false)
		var attack_rotation = player_data.get("attack_rotation", 0.0)
		var ign = player_data.get("ign", "Unknown")
		var is_host_flag = player_data.get("is_host", false)

		var existing_info = MultiplayerManager.players.get(user_id, {})
		MultiplayerManager.players[user_id] = {
			"ign": ign,
			"is_host": is_host_flag,
			"presence": existing_info.get("presence", null)
		}
		_apply_authoritative_player_info(user_id, ign, is_host_flag)
		
		# Handle local player - reconcile with server
		if MultiplayerUtils.is_local_player(user_id):
			MultiplayerUtils.reconcile_local_player(new_pos, velocity, server_seq)
			continue
		
		# Handle remote player
		if not MultiplayerUtils.has_remote_player(user_id):
			# Player not yet spawned - spawn them
			MultiplayerManager.players[user_id] = {
				"ign": ign,
				"is_host": is_host_flag,
				"presence": existing_info.get("presence", null)
			}
			_spawn_player_for_user(user_id)
		
		if MultiplayerUtils.has_remote_player(user_id):
			MultiplayerUtils.update_remote_player_target(user_id, new_pos, velocity, facing, is_attacking, is_dashing, attack_rotation)
			_update_player_minimap_indicator(user_id, new_pos)
			
			# Check for pending attack (slash effect)
			var pending_attack = MultiplayerUtils.get_pending_attack(user_id)
			if not pending_attack.is_empty():
				print("[Main] Spawning remote slash at ", pending_attack.pos, " rotation ", pending_attack.rotation)
				_spawn_remote_slash(pending_attack.pos, pending_attack.rotation)
			
			# Show player if not visible
			var node = MultiplayerUtils.get_remote_player_node(user_id)
			if node and not node.visible and MultiplayerUtils.is_remote_player_visible(user_id):
				node.visible = true
				node.global_position = new_pos
				var sprite = node.get_node_or_null("AnimatedSprite2D")
				if sprite:
					sprite.modulate = Color(1, 1, 1, 0)
					var tween = create_tween()
					tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


## Handle player join from server (op code 3)
func _handle_player_join(data: Dictionary) -> void:
	if data == null:
		return
	
	var user_id = data.get("user_id", "")
	if user_id.is_empty() or MultiplayerUtils.is_local_player(user_id):
		return
	
	var ign = data.get("ign", "Unknown")
	var is_host_flag = data.get("is_host", false)
	var pos_data = data.get("pos", {})
	var spawn_pos = Vector2(pos_data.get("x", 400), pos_data.get("y", 300))
	
	var existing_info = MultiplayerManager.players.get(user_id, {})
	MultiplayerManager.players[user_id] = {
		"ign": ign,
		"is_host": is_host_flag,
		"presence": existing_info.get("presence", null)
	}
	
	if not MultiplayerUtils.has_remote_player(user_id):
		_spawn_player_for_user(user_id, spawn_pos)
	else:
		_apply_authoritative_player_info(user_id, ign, is_host_flag)


func _apply_authoritative_player_info(user_id: String, ign: String, is_host_flag: bool) -> void:
	if user_id.is_empty() or ign.is_empty():
		return

	if user_id == MultiplayerManager.session.user_id:
		player.name = ign
		if player.has_method("set_ign"):
			player.set_ign(ign)
		return

	if MultiplayerUtils.has_remote_player(user_id):
		var remote_player = MultiplayerUtils.get_remote_player_node(user_id)
		if is_instance_valid(remote_player):
			remote_player.name = ign
			if remote_player.has_method("set_ign"):
				remote_player.set_ign(ign)

	if ui and ui.has_method("update_remote_player_ign"):
		ui.update_remote_player_ign(user_id, ign)


## Handle player leave from server (op code 4)
func _handle_player_leave(data: Dictionary) -> void:
	if data == null:
		return
	
	var user_id = data.get("user_id", "")
	if user_id.is_empty():
		return
	
	if MultiplayerManager.players.has(user_id):
		MultiplayerManager.players.erase(user_id)
	
	if MultiplayerUtils.has_remote_player(user_id):
		var node = MultiplayerUtils.get_remote_player_node(user_id)
		if is_instance_valid(node):
			node.queue_free()
		MultiplayerUtils.unregister_remote_player(user_id)
		_remove_player_minimap_indicator(user_id)
