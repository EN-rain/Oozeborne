extends RefCounted
class_name MatchStateRouter

var _main: Node
var _player: Node
var _ui: Node
var _mob_spawner: MobSpawner
var _round_manager: RoundManager


func bind(main: Node, player: Node, ui: Node, mob_spawner: MobSpawner, round_manager: RoundManager) -> void:
	_main = main
	_player = player
	_ui = ui
	_mob_spawner = mob_spawner
	_round_manager = round_manager


func on_match_state(match_state) -> void:
	var op_code = match_state.op_code
	var data = JSON.parse_string(match_state.data)

	if op_code == MultiplayerUtils.OP_STATE:
		_handle_server_snapshot(data)
		_main._refresh_authoritative_host_role()
		return

	if op_code == MultiplayerUtils.OP_PLAYER_JOIN:
		_handle_player_join(data)
		_main._refresh_authoritative_host_role()
		return

	if op_code == MultiplayerUtils.OP_PLAYER_LEAVE:
		_handle_player_leave(data)
		return

	if op_code == MultiplayerUtils.OP_START_GAME:
		_main._debug_log("Received start_game signal while already in game")
		return

	if data == null:
		_main._debug_log("Failed to parse match state data")
		return

	var sender_id := ""
	if match_state.presence != null:
		sender_id = match_state.presence.user_id

	match data.get("type", ""):
		"round_start":
			_handle_round_start(data)
		"mob_spawn":
			_handle_mob_spawn(data)
		"player_stats":
			_handle_player_stats(sender_id, data)
		"player_info":
			var msg_user_id = MultiplayerUtils.extract_user_id_from_data(data)
			if sender_id.is_empty() and not msg_user_id.is_empty():
				sender_id = msg_user_id

			if MultiplayerUtils.is_local_player(sender_id):
				return

			var ign = data.get("ign", "Unknown")
			var is_host_flag = data.get("is_host", false)
			var slime_variant = str(data.get("slime_variant", "blue"))

			if sender_id.is_empty():
				return

			if MultiplayerManager.players.has(sender_id):
				MultiplayerManager.players[sender_id]["ign"] = ign
				MultiplayerManager.players[sender_id]["is_host"] = is_host_flag
				MultiplayerManager.players[sender_id]["slime_variant"] = slime_variant
			else:
				MultiplayerManager.players[sender_id] = {"ign": ign, "is_host": is_host_flag, "presence": null, "slime_variant": slime_variant}

			_main._apply_authoritative_player_info(sender_id, ign, is_host_flag)

		"player_attack":
			var msg_user_id = MultiplayerUtils.extract_user_id_from_data(data)
			if sender_id.is_empty() and not msg_user_id.is_empty():
				sender_id = msg_user_id

		"chat_message":
			var sender_name = data.get("sender", "Unknown")
			var message = data.get("message", "")
			if sender_name.strip_edges() == MultiplayerManager.player_ign.strip_edges():
				return
			var sender_info = MultiplayerManager.players.get(sender_id, {})
			var is_admin = sender_info.get("is_admin", false)
			var is_party_leader = sender_info.get("is_host", false)

			if _ui != null and _ui.has_method("add_chat_message"):
				_ui.add_chat_message(sender_name, message, is_admin, is_party_leader)

		"ping":
			if match_state.presence != null:
				MultiplayerUtils.send_pong(match_state.presence.user_id, data.get("timestamp", 0))

		"pong":
			if data.get("target") == MultiplayerManager.user_id:
				var ping_time = MultiplayerUtils.calculate_ping(data.get("timestamp", 0.0))
				MultiplayerUtils.set_ping(ping_time)

		"request_players":
			MultiplayerUtils.send_player_info(MultiplayerManager.player_ign, MultiplayerManager.is_host)

		"enemy_hit":
			var hit_sender_id := str(data.get("user_id", ""))
			if hit_sender_id.is_empty() or MultiplayerUtils.is_local_player(hit_sender_id):
				return
			var hit_x: float = data.get("enemy_x", 0.0)
			var hit_y: float = data.get("enemy_y", 0.0)
			var hit_dmg: int = data.get("damage", 1)
			_main._apply_remote_enemy_hit(Vector2(hit_x, hit_y), hit_dmg)

		"skill_stat_update":
			var stat_sender_id := str(data.get("user_id", ""))
			if stat_sender_id.is_empty() or MultiplayerUtils.is_local_player(stat_sender_id):
				return
			var skill_tree_manager = _main.get_tree().root.get_node_or_null("SkillTreeManager")
			if skill_tree_manager != null:
				skill_tree_manager.call("handle_remote_skill_stat_update", stat_sender_id, data.get("stats", {}))

		"subclass_selected":
			var subclass_sender_id := str(data.get("user_id", ""))
			if subclass_sender_id.is_empty() or MultiplayerUtils.is_local_player(subclass_sender_id):
				return
			var subclass_id := str(data.get("subclass_id", ""))
			var subclass_res := ClassManager.create_class_instance(subclass_id)
			if subclass_res != null:
				MultiplayerManager.set_player_subclass(subclass_sender_id, subclass_res)
				if MultiplayerUtils.has_remote_player(subclass_sender_id):
					var remote_node = MultiplayerUtils.get_remote_player_node(subclass_sender_id)
					if remote_node != null and remote_node.has_method("apply_subclass_modifiers"):
						remote_node.apply_subclass_modifiers(subclass_res)


func _handle_round_start(data: Dictionary) -> void:
	if data == null or _round_manager == null:
		return
	var round_number := int(data.get("round", 1))
	_round_manager.set_round(round_number)
	if _mob_spawner != null:
		_mob_spawner.begin_network_round(round_number)


func _handle_mob_spawn(data: Dictionary) -> void:
	if data == null or _mob_spawner == null:
		return
	var mob_id := str(data.get("mob_id", ""))
	if mob_id.is_empty():
		return
	if _main._network_mobs.has(mob_id):
		return
	var mob_type := str(data.get("mob_type", "common")).to_lower().strip_edges()
	var pos_data: Dictionary = data.get("pos", {}) if data.get("pos") is Dictionary else {}
	var world_pos := Vector2(float(pos_data.get("x", 0.0)), float(pos_data.get("y", 0.0)))
	var spawned: Node2D = null
	if mob_type in ["common", "slime"]:
		spawned = _mob_spawner.spawn_common_mob_at(world_pos)
	elif mob_type in ["lancer", "archer"]:
		spawned = _mob_spawner.spawn_elite_mob_at(mob_type, world_pos)
	else:
		spawned = _mob_spawner.spawn_mob_by_name_at(mob_type, world_pos)
	if spawned != null:
		spawned.set_meta("network_mob_id", mob_id)
		_main._network_mobs[mob_id] = weakref(spawned)


func _handle_player_stats(sender_id: String, data: Dictionary) -> void:
	if data == null:
		return
	var entry_id := str(data.get("user_id", ""))
	if entry_id.is_empty():
		entry_id = sender_id
	if entry_id.is_empty() or not MultiplayerManager.is_authenticated():
		return
	if entry_id == MultiplayerManager.user_id and not sender_id.is_empty() and sender_id != MultiplayerManager.user_id:
		return

	var existing: Dictionary = MultiplayerManager.players.get(entry_id, {}) if MultiplayerManager.players.get(entry_id) is Dictionary else {}
	if existing.is_empty():
		existing = {"ign": "", "is_host": false, "presence": null, "slime_variant": "blue"}
	var lvl := int(data.get("level", existing.get("level", 1)))
	var hp := int(data.get("hp", existing.get("hp", 0)))
	var hp_max := int(data.get("hp_max", existing.get("hp_max", 0)))
	var mp := int(data.get("mp", existing.get("mp", 0)))
	var mp_max := int(data.get("mp_max", existing.get("mp_max", 0)))

	existing["level"] = lvl
	existing["hp"] = hp
	existing["hp_max"] = hp_max
	existing["mp"] = mp
	existing["mp_max"] = mp_max
	MultiplayerManager.players[entry_id] = existing


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
		var resolved_variant = snapshot_variant if not snapshot_variant.is_empty() else str(existing_info.get("slime_variant", "blue"))
		MultiplayerManager.players[user_id] = {
			"ign": ign,
			"is_host": is_host_flag,
			"presence": existing_info.get("presence", null),
			"slime_variant": resolved_variant
		}
		_main._apply_authoritative_player_info(user_id, ign, is_host_flag)

		if MultiplayerUtils.is_local_player(user_id):
			MultiplayerUtils.reconcile_local_player(new_pos, velocity, server_seq)
			continue

		if not MultiplayerUtils.has_remote_player(user_id):
			MultiplayerManager.players[user_id] = {
				"ign": ign,
				"is_host": is_host_flag,
				"presence": existing_info.get("presence", null),
				"slime_variant": resolved_variant
			}
			_main._spawn_player_for_user(user_id, new_pos)

		if MultiplayerUtils.has_remote_player(user_id):
			MultiplayerUtils.update_remote_player_target(user_id, new_pos, velocity, facing, is_attacking, is_dashing, attack_rotation, attack_seq, dash_seq)
			_main._update_player_minimap_indicator(user_id, new_pos)

			var node = MultiplayerUtils.get_remote_player_node(user_id)
			if node and not node.visible and MultiplayerUtils.is_remote_player_visible(user_id):
				node.visible = true
				node.global_position = new_pos
				var sprite = node.get_node_or_null("AnimatedSprite2D")
				if sprite:
					sprite.modulate = Color(1, 1, 1, 0)
					var tween = _main.create_tween()
					tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _handle_player_join(data: Dictionary) -> void:
	if data == null:
		return

	var user_id = data.get("user_id", "")
	if user_id.is_empty() or MultiplayerUtils.is_local_player(user_id):
		return

	var ign = data.get("ign", "Unknown")
	var is_host_flag = data.get("is_host", false)
	var pos_data = data.get("pos", {})
	var fallback_spawn: Vector2 = _main._get_local_spawn_position()
	var spawn_pos = Vector2(pos_data.get("x", fallback_spawn.x), pos_data.get("y", fallback_spawn.y))

	var existing_info = MultiplayerManager.players.get(user_id, {})
	MultiplayerManager.players[user_id] = {
		"ign": ign,
		"is_host": is_host_flag,
		"presence": existing_info.get("presence", null),
		"slime_variant": existing_info.get("slime_variant", "blue")
	}

	if not MultiplayerUtils.has_remote_player(user_id):
		_main._spawn_player_for_user(user_id, spawn_pos)
	else:
		_main._apply_authoritative_player_info(user_id, ign, is_host_flag)


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
		_main._remove_player_minimap_indicator(user_id)

