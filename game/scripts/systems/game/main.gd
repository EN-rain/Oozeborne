extends Node2D

const ClassManagerScript := preload("res://scripts/globals/class_manager.gd")

@onready var player = $Player
@onready var ui = $HUD
@onready var spawn_point: Marker2D = %SpawnPoint
@onready var _subclass_overlay_layer: CanvasLayer = %SubclassOverlayLayer
@onready var _subclass_overlay_choices: VBoxContainer = %SubclassChoicesVBox

@export var player_scene: PackedScene

@export var common_mob_scene: PackedScene
@export var elite_lancer_scene: PackedScene
@export var elite_archer_scene: PackedScene

var mob_spawner: MobSpawner
var round_manager: RoundManager

const LOCAL_PLAYER_SPAWN_FADE_TIME := 0.35
const SOLO_CLASS_SELECTION_NODE_PATH := "SoloClassSelection"
const DEBUG_STATS_LABEL_NODE_PATH := "Control/DebugStatsLabel"
const DEBUG_MAIN_LOGS := false

var _solo_class_selection_ui: ClassSelectionUI = null
var _solo_class_locked: bool = false
var _starting_round_transition: bool = false
# FPS/Ping display
var _fps_label: Label
@onready var _ping_timer: Timer = %PingTimer

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
	
	# Use authored spawn point when available, fallback to legacy host/client spawn.
	player.global_position = _get_local_spawn_position()
	_play_local_spawn_intro()
	
	_bind_local_player(player)
	spawn_players()
	
	# Use scene-defined camera setup.
	_setup_player_camera()

	round_manager = RoundManager.new()
	add_child(round_manager)
	
	# Initialize mob spawner
	mob_spawner = MobSpawner.new()
	mob_spawner.name = "MobSpawner"
	mob_spawner.common_mob_scene = common_mob_scene
	mob_spawner.elite_mob_lancer_scene = elite_lancer_scene
	mob_spawner.elite_mob_archer_scene = elite_archer_scene
	mob_spawner.initialize(self, player)
	mob_spawner.set_round_manager(round_manager)
	mob_spawner.mob_spawned.connect(_on_mob_spawned)
	mob_spawner.mob_died.connect(_on_mob_died)
	mob_spawner.active_mob_count_changed.connect(_on_active_mob_count_changed)
	mob_spawner.round_cleared.connect(_on_round_cleared)
	add_child(mob_spawner)
	_sync_hud_bindings()
	_restore_saved_solo_run_if_needed()
	
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
	
	if _should_show_solo_class_selection():
		_show_solo_class_selection_overlay()
	else:
		call_deferred("_start_round", round_manager.current_round, false)
	call_deferred("_ensure_solo_class_selection_visible")

	if not LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.connect(_on_level_up)

	_maybe_prompt_subclass_selection()


func build_solo_run_snapshot() -> Dictionary:
	if not is_instance_valid(player) or ui == null or round_manager == null:
		return {}
	var class_id := ClassManagerScript.get_class_id(MultiplayerManager.player_class) if MultiplayerManager.player_class != null else ""
	if class_id.is_empty():
		return {}
	var subclass_id := ClassManagerScript.get_class_id(MultiplayerManager.player_subclass) if MultiplayerManager.player_subclass != null else ""
	return {
		"scene_path": scene_file_path,
		"player_class_id": class_id,
		"player_class_name": MultiplayerManager.player_class.display_name if MultiplayerManager.player_class != null else "",
		"player_subclass_id": subclass_id,
		"subclass_choice_made": MultiplayerManager.subclass_choice_made,
		"player_level": LevelSystem.get_level(player),
		"player_xp": LevelSystem.get_xp(player),
		"skill_tree_state": SkillTreeManager.save_state(),
		"coins": CoinManager.get_coins(),
		"score": ui.get_current_score() if ui.has_method("get_current_score") else 0,
		"round": round_manager.current_round,
	}


func _restore_saved_solo_run_if_needed() -> void:
	var snapshot: Dictionary = SoloRunSaveManager.consume_pending_continue_snapshot()
	if snapshot.is_empty():
		return
	var class_id := str(snapshot.get("player_class_id", ""))
	if not class_id.is_empty():
		MultiplayerManager.player_class = ClassManagerScript.create_class_instance(class_id)
	var subclass_id := str(snapshot.get("player_subclass_id", ""))
	MultiplayerManager.player_subclass = ClassManagerScript.create_class_instance(subclass_id) if not subclass_id.is_empty() else null
	MultiplayerManager.subclass_choice_made = bool(snapshot.get("subclass_choice_made", false))
	MultiplayerManager.player_level = int(snapshot.get("player_level", 1))
	if is_instance_valid(player):
		LevelSystem.load_player_state(player, {
			"level": int(snapshot.get("player_level", 1)),
			"xp": int(snapshot.get("player_xp", 0)),
		})
	if snapshot.has("skill_tree_state"):
		SkillTreeManager.load_state(snapshot.get("skill_tree_state", {}))
	if CoinManager != null and CoinManager.has_method("set_coins"):
		CoinManager.set_coins(int(snapshot.get("coins", 0)))
	if ui != null and ui.has_method("set_current_score"):
		ui.set_current_score(int(snapshot.get("score", 0)))
	if round_manager != null:
		round_manager.current_round = max(1, int(snapshot.get("round", 1)))
	_refresh_local_player_runtime_state(player)


func _bind_local_player(target_player: Node) -> void:
	player = target_player
	if player == null:
		return
	if MultiplayerManager.session != null:
		player.set_meta("network_user_id", str(MultiplayerManager.session.user_id))
	else:
		player.set_meta("network_user_id", "solo")
	call_deferred("_finalize_local_player_binding", player)


func _finalize_local_player_binding(target_player: Node) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	if not LevelSystem.has_player(target_player):
		LevelSystem.register_player(target_player, max(1, MultiplayerManager.player_level))
	if target_player.has_method("_apply_class_modifiers"):
		target_player.call("_apply_class_modifiers")
	if mob_spawner != null:
		mob_spawner.initialize(self, target_player)
	if MultiplayerManager.socket:
		MultiplayerUtils.set_local_player(target_player)
	_sync_hud_bindings()
	_setup_player_camera()
	call_deferred("_refresh_local_player_runtime_state_after_frame", target_player)
	if ui != null:
		if ui.has_method("refresh_player_level_display"):
			ui.call("refresh_player_level_display")
		if ui.has_method("refresh_player_stat_cards"):
			ui.call("refresh_player_stat_cards")


func _refresh_local_player_runtime_state(target_player: Node) -> void:
	_finalize_local_player_binding(target_player)


func _refresh_local_player_runtime_state_after_frame(target_player: Node) -> void:
	await get_tree().process_frame
	if target_player == null or not is_instance_valid(target_player):
		return
	if not LevelSystem.has_player(target_player):
		LevelSystem.register_player(target_player, max(1, MultiplayerManager.player_level))
	LevelSystem.set_level(target_player, LevelSystem.get_level(target_player))
	if target_player.has_method("_apply_class_modifiers"):
		target_player.call("_apply_class_modifiers")
	if ui != null:
		if ui.has_method("set_player"):
			ui.call("set_player", target_player)
		if ui.has_method("refresh_player_level_display"):
			ui.call("refresh_player_level_display")
		if ui.has_method("refresh_player_stat_cards"):
			ui.call("refresh_player_stat_cards")


func _sync_hud_bindings() -> void:
	if ui == null or player == null:
		return
	ui.set_player(player)
	if mob_spawner != null:
		ui.set_mob_spawner(mob_spawner)


func _setup_player_camera() -> void:
	if not is_instance_valid(player):
		push_warning("[Main] Cannot setup camera - player not valid")
		return

	var existing_camera := player.get_node_or_null("Camera2D") as Camera2D
	if existing_camera == null:
		push_warning("[Main] Player scene is missing Camera2D. Add one in the player scene.")
		return

	existing_camera.make_current()
	_debug_log("Using scene Camera2D on player")


func _play_local_spawn_intro() -> void:
	if not is_instance_valid(player):
		return
	player.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "modulate:a", 1.0, LOCAL_PLAYER_SPAWN_FADE_TIME)

func _replace_local_player_with_class_scene():
	# Apply the correct slime variant visuals to the existing player
	# Always use the lobby-assigned slime_variant, NOT the class's player_scene
	# (the class's player_scene may point to a different variant color)
	var variant: String = MultiplayerManager.player_slime_variant
	
	var scene_to_use: PackedScene = null
	if not variant.is_empty():
		var variant_scene_path: String = SlimePaletteRegistry.get_scene_path(variant)
		var variant_scene = load(variant_scene_path) as PackedScene
		if variant_scene != null:
			scene_to_use = variant_scene
	
	if scene_to_use != null:
		_apply_variant_visuals_to_player(scene_to_use)


func _get_local_spawn_position() -> Vector2:
	if spawn_point != null:
		return spawn_point.global_position
	return Vector2(360, 300) if MultiplayerManager.is_host else Vector2(440, 300)


func _apply_local_player_class(player_class: PlayerClass) -> void:
	if player_class == null or player_class.player_scene == null or not is_instance_valid(player):
		return
	_apply_variant_visuals_to_player(player_class.player_scene)


func _apply_variant_visuals_to_player(scene: PackedScene) -> void:
	# Instantiate the variant scene temporarily to extract visual components
	var ref_node = scene.instantiate()
	var ref_sprite = ref_node.get_node_or_null("AnimatedSprite2D")
	var local_sprite = player.get_node_or_null("AnimatedSprite2D")
	
	if ref_sprite and local_sprite:
		# Copy sprite frames (animations)
		if ref_sprite.sprite_frames:
			local_sprite.sprite_frames = ref_sprite.sprite_frames.duplicate(true)
		# Copy shader material (slime color)
		if ref_sprite.material:
			local_sprite.material = ref_sprite.material.duplicate()
		# Reset animation
		local_sprite.animation = &"idle"
		local_sprite.frame = 0
	
	# Free the temporary reference node (never added to tree)
	ref_node.free()
	_debug_log("Applied variant visuals from scene: %s" % scene.resource_path)


func _apply_remote_variant_visuals(remote_player: Node, variant: String, _remote_class: PlayerClass) -> void:
	# Always use the slime_variant from player data (lobby-assigned), NOT the class's player_scene
	# The class's player_scene may point to a different variant than what the player chose in the lobby
	var scene_to_use: PackedScene = null
	if not variant.is_empty():
		scene_to_use = MultiplayerManager._cached_player_scenes.get(variant) as PackedScene
		if scene_to_use == null:
			scene_to_use = load(SlimePaletteRegistry.get_scene_path(variant)) as PackedScene
			if scene_to_use != null:
				MultiplayerManager._cached_player_scenes[variant] = scene_to_use
	if scene_to_use == null:
		return
	
	var ref_node = scene_to_use.instantiate()
	var ref_sprite = ref_node.get_node_or_null("AnimatedSprite2D")
	var remote_sprite = remote_player.get_node_or_null("AnimatedSprite2D")
	
	if ref_sprite and remote_sprite:
		if ref_sprite.sprite_frames:
			remote_sprite.sprite_frames = ref_sprite.sprite_frames.duplicate(true)
		if ref_sprite.material:
			remote_sprite.material = ref_sprite.material.duplicate()
		remote_sprite.animation = &"idle"
		remote_sprite.frame = 0
	
	ref_node.free()
	_debug_log("Applied remote variant visuals: %s" % variant)


func _should_show_solo_class_selection() -> bool:
	return MultiplayerManager.player_class == null and not MultiplayerManager.is_socket_open() and MultiplayerManager.match_id.is_empty()


func _ensure_solo_class_selection_visible() -> void:
	if not _should_show_solo_class_selection():
		return
	var solo_ui := ui.get_node_or_null(SOLO_CLASS_SELECTION_NODE_PATH)
	if solo_ui == null:
		return
	if solo_ui.visible:
		return
	_show_solo_class_selection_overlay()


func _show_solo_class_selection_overlay() -> void:
	_solo_class_selection_ui = ui.get_node_or_null(SOLO_CLASS_SELECTION_NODE_PATH) as ClassSelectionUI
	if _solo_class_selection_ui == null:
		push_warning("[Main] Missing UI node: %s" % SOLO_CLASS_SELECTION_NODE_PATH)
		return
	
	_solo_class_selection_ui.auto_start_solo_game = false
	_solo_class_selection_ui.set_player_level(MultiplayerManager.player_level)
	if not _solo_class_selection_ui.class_selected.is_connected(_on_solo_class_selected):
		_solo_class_selection_ui.class_selected.connect(_on_solo_class_selected)
	_solo_class_selection_ui.visible = true
	
	_solo_class_locked = true
	player.set_physics_process(false)


func _on_solo_class_selected(selected_class: PlayerClass, _selected_subclass: PlayerClass) -> void:
	var class_id := ClassManagerScript.get_class_id(selected_class)
	var resolved_class := ClassManagerScript.create_class_instance(class_id) if not class_id.is_empty() else selected_class
	resolved_class.player_scene = MultiplayerManager.resolve_player_scene()
	MultiplayerManager.player_class = resolved_class
	MultiplayerManager.player_subclass = null
	MultiplayerManager.subclass_choice_made = false
	_apply_local_player_class(resolved_class)
	_finish_solo_class_selection()


func _finish_solo_class_selection() -> void:
	_solo_class_locked = false
	if is_instance_valid(player):
		player.set_physics_process(true)
	if is_instance_valid(_solo_class_selection_ui):
		_solo_class_selection_ui.visible = false
	_solo_class_selection_ui = null
	call_deferred("_start_initial_mob_spawns")


func _start_initial_mob_spawns() -> void:
	if mob_spawner == null or not is_instance_valid(player):
		return
	_setup_player_camera()
	mob_spawner.initialize(self, player)
	call_deferred("_start_round", round_manager.current_round, false)

func _create_fps_display():
	_fps_label = ui.get_node_or_null(DEBUG_STATS_LABEL_NODE_PATH) as Label
	if _fps_label == null:
		push_warning("[Main] Missing UI node: %s" % DEBUG_STATS_LABEL_NODE_PATH)
	else:
		_fps_label.visible = true
	
	if _ping_timer and not _ping_timer.timeout.is_connected(_on_ping_timeout):
		_ping_timer.timeout.connect(_on_ping_timeout)
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
		_debug_log("Received start_game signal while already in game")
		return
	
	# Legacy JSON-based messages (for compatibility)
	if data == null:
		_debug_log("Failed to parse match state data")
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
			var slime_variant = str(data.get("slime_variant", "blue"))
			
			# Skip if still empty after trying to get from data
			if sender_id.is_empty():
				return
			
			# Add or update player - preserve presence if already stored
			if MultiplayerManager.players.has(sender_id):
				MultiplayerManager.players[sender_id]["ign"] = ign
				MultiplayerManager.players[sender_id]["is_host"] = is_host_flag
				MultiplayerManager.players[sender_id]["slime_variant"] = slime_variant
			else:
				MultiplayerManager.players[sender_id] = {"ign": ign, "is_host": is_host_flag, "presence": null, "slime_variant": slime_variant}

			_apply_authoritative_player_info(sender_id, ign, is_host_flag)
			# Don't spawn here - player_info doesn't have position data
			# Players will be spawned from OP_PLAYER_JOIN and server snapshots
		
		
		"player_attack":
			# Get user_id from data if sender_id is empty (broadcast echo)
			var msg_user_id = MultiplayerUtils.extract_user_id_from_data(data)
			if sender_id.is_empty() and not msg_user_id.is_empty():
				sender_id = msg_user_id
		
		"chat_message":
			var sender_name = data.get("sender", "Unknown")
			var message = data.get("message", "")
			# Skip own messages - chat_box already shows them locally on send
			if sender_name.strip_edges() == MultiplayerManager.player_ign.strip_edges():
				return
			var sender_info = MultiplayerManager.players.get(sender_id, {})
			var is_admin = sender_info.get("is_admin", false)
			var is_party_leader = sender_info.get("is_host", false)
			
			if ui != null and ui.has_method("add_chat_message"):
				ui.add_chat_message(sender_name, message, is_admin, is_party_leader)
		
		
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

		"skill_stat_update":
			var stat_sender_id := str(data.get("user_id", ""))
			if stat_sender_id.is_empty() or MultiplayerUtils.is_local_player(stat_sender_id):
				return
			var skill_tree_manager = get_tree().root.get_node_or_null("SkillTreeManager")
			if skill_tree_manager != null:
				skill_tree_manager.call("handle_remote_skill_stat_update", stat_sender_id, data.get("stats", {}))

		"subclass_selected":
			var subclass_sender_id := str(data.get("user_id", ""))
			if subclass_sender_id.is_empty() or MultiplayerUtils.is_local_player(subclass_sender_id):
				return
			var subclass_id := str(data.get("subclass_id", ""))
			var subclass_res := ClassManagerScript.create_class_instance(subclass_id)
			if subclass_res != null:
				MultiplayerManager.set_player_subclass(subclass_sender_id, subclass_res)
				if MultiplayerUtils.has_remote_player(subclass_sender_id):
					var remote_node = MultiplayerUtils.get_remote_player_node(subclass_sender_id)
					if remote_node != null and remote_node.has_method("apply_subclass_modifiers"):
						remote_node.apply_subclass_modifiers(subclass_res)

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
		# Spawn remote player - use base player scene and apply variant visuals
		var remote_variant: String = str(player_info.get("slime_variant", "blue"))
		var remote_player_class: PlayerClass = MultiplayerManager.get_player_class(user_id)
		if player_scene == null:
			return
		var remote_player = player_scene.instantiate()
		var has_initial_pos := initial_pos is Vector2
		var spawn_pos: Vector2 = initial_pos if has_initial_pos else Vector2(-9999, -9999)
		remote_player.global_position = spawn_pos
		remote_player.visible = has_initial_pos
		remote_player.is_local_player = false  # Mark as remote player - this disables physics
		remote_player.set_meta("network_user_id", user_id)
		remote_player.velocity = Vector2.ZERO  # Reset velocity
		var remote_collision = remote_player.get_node_or_null("CollisionShape2D")
		if remote_collision:
			remote_collision.set_deferred("disabled", true)
		if player_info.has("ign"):
			remote_player.name = player_info.ign
			if remote_player.has_method("set_ign"):
				remote_player.set_ign(player_info.ign)
		var remote_subclass: PlayerClass = MultiplayerManager.get_player_subclass(user_id)
		if remote_subclass != null and remote_player.has_method("apply_subclass_modifiers"):
			remote_player.apply_subclass_modifiers(remote_subclass)
		# Apply variant visuals (sprite frames + shader material) for correct color
		_apply_remote_variant_visuals(remote_player, remote_variant, remote_player_class)
		add_child(remote_player)
		# Ensure remote player cannot collide with anyone (passthrough)
		remote_player.collision_layer = 0
		remote_player.collision_mask = 0
		# Register with MultiplayerUtils for interpolation
		MultiplayerUtils.register_remote_player(user_id, remote_player, spawn_pos, has_initial_pos)
		# Add green dot indicator for this player on the minimap
		_add_player_minimap_indicator(user_id, spawn_pos)
		_apply_authoritative_player_info(user_id, player_info.get("ign", ""), player_info.get("is_host", false))

func _spawn_remote_attack(user_id: String, _pos: Vector2, rotation_angle: float):
	# Spawn slash particles for remote player
	if not MultiplayerUtils.has_remote_player(user_id):
		_debug_log("Remote player not found for attack: %s" % user_id)
		return
	
	var player_data = MultiplayerUtils.get_remote_players()[user_id]
	var remote_player = player_data.node
	
	# Use the remote player's current visual position for the slash
	if is_instance_valid(remote_player) and remote_player.has_method("emit_attack_particles_at"):
		var attack_dir := Vector2(cos(rotation_angle), sin(rotation_angle))
		var slash_pos: Vector2 = remote_player.global_position + attack_dir * 12
		_debug_log("Spawning remote attack for %s at %s rotation %s" % [user_id, slash_pos, rotation_angle])
		remote_player.emit_attack_particles_at(slash_pos, rotation_angle)
	else:
		_debug_log("Remote player %s invalid or missing emit_attack_particles_at method" % user_id)


func _find_remote_player_near_position(pos: Vector2, max_distance: float = 64.0) -> Node:
	var best_node: Node = null
	var best_distance_sq: float = max_distance * max_distance
	for data in MultiplayerUtils.get_remote_players().values():
		var node: Node2D = data.get("node") as Node2D
		if node == null or not is_instance_valid(node):
			continue
		var dist_sq: float = node.global_position.distance_squared_to(pos)
		if dist_sq <= best_distance_sq:
			best_distance_sq = dist_sq
			best_node = node
	return best_node


func send_attack(pos: Vector2, rotation_angle: float):
	# Send attack to other players
	MultiplayerUtils.send_attack(pos, rotation_angle)

func _on_match_presence(presence_event):
	# Handle players joining during game
	for join in presence_event.joins:
		_debug_log("Player joined match: user_id=%s" % join.user_id.substr(0, 8))
		# Skip if this is ourselves
		if join.user_id == MultiplayerManager.session.user_id:
			continue
		if not MultiplayerManager.players.has(join.user_id):
			MultiplayerManager.players[join.user_id] = {"ign": "", "is_host": false, "presence": join, "slime_variant": "blue"}
			_debug_log("Added to players dict. Total players: %d" % MultiplayerManager.players.size())
			MultiplayerManager.player_joined.emit(join.user_id, "Player", false)
		else:
			MultiplayerManager.players[join.user_id]["presence"] = join
	
	# Handle players leaving
	for leave in presence_event.leaves:
		var user_id = leave.user_id
		# Skip if this is ourselves (Nakama sometimes sends our own leave event)
		if user_id == MultiplayerManager.session.user_id:
			continue
		_debug_log("Player left match: %s" % leave.username)
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
	if round_manager != null:
		round_manager.register_mob(mob)
	ui.register_slime(mob)

func _on_mob_died(_mob, score_value: int, xp_value: int):
	ui.add_score(score_value)
	# Award XP to local player via singleton
	if player:
		LevelSystem.add_xp(player, xp_value)
		_debug_log("Awarded %d XP to player" % xp_value)


func _on_active_mob_count_changed(current_alive: int, total_in_round: int) -> void:
	if ui != null and ui.has_method("update_mob_counter"):
		ui.update_mob_counter(current_alive, total_in_round)


func _on_round_cleared(round_number: int) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	call_deferred("_start_next_round_after_clear", round_number)


func _start_next_round_after_clear(round_number: int) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	await _start_round(round_number + 1, true)


func _start_round(round_number: int, show_popup: bool) -> void:
	if _starting_round_transition or mob_spawner == null or not is_inside_tree() or is_queued_for_deletion():
		return
	_starting_round_transition = true

	round_manager.set_round(round_number)
	var profile := round_manager.get_round_profile(round_number)
	var added_mobs := mob_spawner.get_round_added_mobs(round_number)
	var total_mobs := mob_spawner.get_round_total_mobs(round_number)

	if ui != null:
		ui.update_mob_counter(total_mobs, total_mobs)
		if show_popup and ui.has_method("show_round_level"):
			ui.show_round_level(round_number, added_mobs, profile)
			var tree := get_tree()
			if tree == null:
				_starting_round_transition = false
				return
			await tree.create_timer(1.7).timeout
			if not is_inside_tree() or is_queued_for_deletion() or mob_spawner == null:
				_starting_round_transition = false
				return

	mob_spawner.start_round(round_number)
	_starting_round_transition = false

func _on_player_joined(user_id: String, username: String, _is_host: bool):
	_debug_log("Player joined signal received for: %s" % username)
	_spawn_player_for_user(user_id)


func _on_level_up(entity_id: int, new_level: int, _stats: Dictionary) -> void:
	if not is_instance_valid(player):
		return
	if entity_id != player.get_instance_id():
		return
	MultiplayerManager.player_level = new_level
	_maybe_prompt_subclass_selection()


func _maybe_prompt_subclass_selection() -> void:
	if not is_instance_valid(player):
		return
	if MultiplayerManager.subclass_choice_made:
		return
	if MultiplayerManager.player_subclass != null:
		return
	if MultiplayerManager.player_class == null:
		return
	if LevelSystem.get_level(player) < 10:
		return
	var overlay_has_choices := _subclass_overlay_choices != null and _subclass_overlay_choices.get_child_count() > 0
	if _subclass_overlay_layer.visible and overlay_has_choices:
		return

	var choices: Array[PlayerClass] = ClassManagerScript.get_subclasses_for_main_class(MultiplayerManager.player_class)
	if choices.is_empty():
		_clear_subclass_selection_overlay()
		return

	_show_subclass_selection_overlay(choices)


func _show_subclass_selection_overlay(choices: Array[PlayerClass]) -> void:
	_clear_subclass_choice_buttons()

	for subclass in choices:
		var button := Button.new()
		button.text = "%s - %s" % [subclass.display_name, subclass.description]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 54)
		button.pressed.connect(_on_subclass_choice_selected.bind(subclass))
		_subclass_overlay_choices.add_child(button)

	_subclass_overlay_layer.visible = true


func _on_subclass_choice_selected(subclass: PlayerClass) -> void:
	if subclass == null:
		return
	MultiplayerManager.player_subclass = subclass
	MultiplayerManager.subclass_choice_made = true
	if MultiplayerManager.session != null:
		MultiplayerManager.set_player_subclass(MultiplayerManager.session.user_id, subclass)
	if is_instance_valid(player) and player.has_method("apply_subclass_modifiers"):
		player.apply_subclass_modifiers(subclass)
	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty() and MultiplayerManager.session != null:
		MultiplayerManager.send_match_state({
			"type": "subclass_selected",
			"user_id": MultiplayerManager.session.user_id,
			"subclass_id": ClassManagerScript.get_class_id(subclass)
		})
	_clear_subclass_selection_overlay()
	_debug_log("Subclass selected: %s" % subclass.display_name)


func _clear_subclass_selection_overlay() -> void:
	_clear_subclass_choice_buttons()
	_subclass_overlay_layer.visible = false


func _clear_subclass_choice_buttons() -> void:
	for child in _subclass_overlay_choices.get_children():
		child.queue_free()


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
		var attack_seq = int(player_data.get("attack_seq", 0))
		var dash_seq = int(player_data.get("dash_seq", 0))
		var ign = player_data.get("ign", "Unknown")
		var is_host_flag = player_data.get("is_host", false)
		var snapshot_variant = str(player_data.get("slime_variant", ""))

		var existing_info = MultiplayerManager.players.get(user_id, {})
		# Prefer snapshot variant, fall back to existing, then default
		var resolved_variant = snapshot_variant if not snapshot_variant.is_empty() else str(existing_info.get("slime_variant", "blue"))
		MultiplayerManager.players[user_id] = {
			"ign": ign,
			"is_host": is_host_flag,
			"presence": existing_info.get("presence", null),
			"slime_variant": resolved_variant
		}
		_apply_authoritative_player_info(user_id, ign, is_host_flag)
		
		# Handle local player - reconcile with server
		if MultiplayerUtils.is_local_player(user_id):
			MultiplayerUtils.reconcile_local_player(new_pos, velocity, server_seq)
			continue
		
		# Handle remote player
		if not MultiplayerUtils.has_remote_player(user_id):
			# Player not yet spawned - spawn them with initial position
			MultiplayerManager.players[user_id] = {
				"ign": ign,
				"is_host": is_host_flag,
				"presence": existing_info.get("presence", null),
				"slime_variant": resolved_variant
			}
			_spawn_player_for_user(user_id, new_pos)
		
		if MultiplayerUtils.has_remote_player(user_id):
			MultiplayerUtils.update_remote_player_target(user_id, new_pos, velocity, facing, is_attacking, is_dashing, attack_rotation, attack_seq, dash_seq)
			_update_player_minimap_indicator(user_id, new_pos)
			
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
	var fallback_spawn := _get_local_spawn_position()
	var spawn_pos = Vector2(pos_data.get("x", fallback_spawn.x), pos_data.get("y", fallback_spawn.y))
	
	var existing_info = MultiplayerManager.players.get(user_id, {})
	MultiplayerManager.players[user_id] = {
		"ign": ign,
		"is_host": is_host_flag,
		"presence": existing_info.get("presence", null),
		"slime_variant": existing_info.get("slime_variant", "blue")
	}
	
	if not MultiplayerUtils.has_remote_player(user_id):
		_spawn_player_for_user(user_id, spawn_pos)
	else:
		_apply_authoritative_player_info(user_id, ign, is_host_flag)


func _apply_authoritative_player_info(user_id: String, ign: String, _is_host_flag: bool) -> void:
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


func _debug_log(message: String) -> void:
	if DEBUG_MAIN_LOGS:
		print("[Main] %s" % message)
