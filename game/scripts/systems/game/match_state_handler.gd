extends Node
## MatchStateHandler - Handles parsing and dispatching match state events
## Add as child to your game scene to handle network events

## Signals for event dispatch
signal player_info_received(user_id: String, ign: String, is_host: bool, slime_variant: String)
signal player_attack_received(user_id: String, pos: Vector2, rotation: float)
signal ping_received(sender_id: String, timestamp: float)
signal pong_received(target_id: String, timestamp: float)
signal request_players_received()


## Handle incoming match state
func handle_match_state(match_state) -> void:
	var op_code = match_state.op_code
	var payload = JSON.parse_string(match_state.data)
	
	# Op code 2 = Server state snapshot (handled by main.gd)
	if op_code == NetworkMessaging.OP_STATE:
		return  # Let main.gd handle this directly
	
	# Op code 3 = Player joined
	if op_code == NetworkMessaging.OP_PLAYER_JOIN:
		return  # Let main.gd handle this directly
	
	# Op code 4 = Player left
	if op_code == NetworkMessaging.OP_PLAYER_LEAVE:
		return  # Let main.gd handle this directly
	
	# Legacy JSON-based messages
	if payload == null:
		return
	
	var sender_id = NetworkMessaging.extract_sender_id(match_state)
	
	match payload.get("type", ""):
		"player_info":
			_handle_player_info(payload, sender_id)
		
		"player_attack":
			_handle_player_attack(payload, sender_id)
		
		"ping":
			_handle_ping(payload, sender_id)
		
		"pong":
			_handle_pong(payload, sender_id)
		
		"request_players":
			request_players_received.emit()


## Parse server snapshot data
func parse_server_snapshot(snapshot: Dictionary) -> Array:
	if snapshot == null:
		return []
	return snapshot.get("players", [])


## Parse player join data
func parse_player_join(payload: Dictionary) -> Dictionary:
	if payload == null:
		return {}
	return {
		"user_id": payload.get("user_id", ""),
		"ign": payload.get("ign", "Unknown"),
		"pos": Vector2(
			payload.get("pos", {}).get("x", 400),
			payload.get("pos", {}).get("y", 300)
		)
	}


## Parse player leave data
func parse_player_leave(payload: Dictionary) -> String:
	if payload == null:
		return ""
	return payload.get("user_id", "")


## Parse player data from snapshot
func parse_player_data(snapshot_player: Dictionary) -> Dictionary:
	var pos_data = snapshot_player.get("pos", {})
	var vel_data = snapshot_player.get("vel", {})
	
	return {
		"user_id": snapshot_player.get("user_id", ""),
		"pos": Vector2(pos_data.get("x", 0), pos_data.get("y", 0)),
		"velocity": Vector2(vel_data.get("x", 0), vel_data.get("y", 0)),
		"input_seq": snapshot_player.get("input_seq", 0),
		"facing": snapshot_player.get("facing", 1),
		"is_attacking": snapshot_player.get("is_attacking", false),
		"is_dashing": snapshot_player.get("is_dashing", false),
		"attack_rotation": snapshot_player.get("attack_rotation", 0.0),
		"ign": snapshot_player.get("ign", "Unknown")
	}


# === INTERNAL HANDLERS ===

func _handle_player_info(data: Dictionary, sender_id: String) -> void:
	var msg_user_id = NetworkMessaging.extract_user_id_from_data(data)
	if sender_id.is_empty() and not msg_user_id.is_empty():
		sender_id = msg_user_id
	
	if NetworkMessaging.is_local_player(sender_id):
		return
	
	var ign = data.get("ign", "Unknown")
	var is_host_flag = data.get("is_host", false)
	var slime_variant = str(data.get("slime_variant", "blue"))
	
	if ign == MultiplayerManager.player_ign:
		return
	
	if sender_id.is_empty():
		return
	
	player_info_received.emit(sender_id, ign, is_host_flag, slime_variant)


func _handle_player_attack(data: Dictionary, sender_id: String) -> void:
	var msg_user_id = NetworkMessaging.extract_user_id_from_data(data)
	if sender_id.is_empty() and not msg_user_id.is_empty():
		sender_id = msg_user_id
	
	if NetworkMessaging.is_local_player(sender_id):
		return
	
	# Support both new server-validated format and legacy format
	var pos: Vector2
	if data.has("attack_x"):
		pos = Vector2(data.get("attack_x", 0.0), data.get("attack_y", 0.0))
	else:
		var attack_pos = data.get("pos", {})
		pos = Vector2(attack_pos.get("x", 0), attack_pos.get("y", 0))
	var attack_rot = data.get("attack_rotation", data.get("rot", 0.0))
	
	player_attack_received.emit(sender_id, pos, attack_rot)


func _handle_ping(data: Dictionary, sender_id: String) -> void:
	if not sender_id.is_empty():
		ping_received.emit(sender_id, data.get("timestamp", 0))


func _handle_pong(data: Dictionary, _sender_id: String) -> void:
	var target = data.get("target", "")
	pong_received.emit(target, data.get("timestamp", 0))
