extends Node
## MatchStateHandler - Handles parsing and dispatching match state events
## Add as child to your game scene to handle network events

## Signals for event dispatch
signal player_info_received(user_id: String, ign: String, is_host: bool)
signal player_attack_received(user_id: String, pos: Vector2, rotation: float)
signal ping_received(sender_id: String, timestamp: float)
signal pong_received(target_id: String, timestamp: float)
signal request_players_received()


## Handle incoming match state
func handle_match_state(match_state) -> void:
	var op_code = match_state.op_code
	var data = JSON.parse_string(match_state.data)
	
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
	if data == null:
		return
	
	var sender_id = NetworkMessaging.extract_sender_id(match_state)
	
	match data.get("type", ""):
		"player_info":
			_handle_player_info(data, sender_id)
		
		"player_attack":
			_handle_player_attack(data, sender_id)
		
		"ping":
			_handle_ping(data, sender_id)
		
		"pong":
			_handle_pong(data, sender_id)
		
		"request_players":
			request_players_received.emit()


## Parse server snapshot data
func parse_server_snapshot(data: Dictionary) -> Array:
	if data == null:
		return []
	return data.get("players", [])


## Parse player join data
func parse_player_join(data: Dictionary) -> Dictionary:
	if data == null:
		return {}
	return {
		"user_id": data.get("user_id", ""),
		"ign": data.get("ign", "Unknown"),
		"pos": Vector2(
			data.get("pos", {}).get("x", 400),
			data.get("pos", {}).get("y", 300)
		)
	}


## Parse player leave data
func parse_player_leave(data: Dictionary) -> String:
	if data == null:
		return ""
	return data.get("user_id", "")


## Parse player data from snapshot
func parse_player_data(player_data: Dictionary) -> Dictionary:
	var pos_data = player_data.get("pos", {})
	var vel_data = player_data.get("vel", {})
	
	return {
		"user_id": player_data.get("user_id", ""),
		"pos": Vector2(pos_data.get("x", 0), pos_data.get("y", 0)),
		"velocity": Vector2(vel_data.get("x", 0), vel_data.get("y", 0)),
		"input_seq": player_data.get("input_seq", 0),
		"facing": player_data.get("facing", 1),
		"is_attacking": player_data.get("is_attacking", false),
		"is_dashing": player_data.get("is_dashing", false),
		"attack_rotation": player_data.get("attack_rotation", 0.0),
		"ign": player_data.get("ign", "Unknown")
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
	
	if ign == MultiplayerManager.player_ign:
		return
	
	if sender_id.is_empty():
		return
	
	player_info_received.emit(sender_id, ign, is_host_flag)


func _handle_player_attack(data: Dictionary, sender_id: String) -> void:
	var msg_user_id = NetworkMessaging.extract_user_id_from_data(data)
	if sender_id.is_empty() and not msg_user_id.is_empty():
		sender_id = msg_user_id
	
	if NetworkMessaging.is_local_player(sender_id):
		return
	
	var attack_pos = data.get("pos", {})
	var attack_rot = data.get("rot", 0.0)
	var pos = Vector2(attack_pos.get("x", 0), attack_pos.get("y", 0))
	
	player_attack_received.emit(sender_id, pos, attack_rot)


func _handle_ping(data: Dictionary, sender_id: String) -> void:
	if not sender_id.is_empty():
		ping_received.emit(sender_id, data.get("timestamp", 0))


func _handle_pong(data: Dictionary, sender_id: String) -> void:
	var target = data.get("target", "")
	pong_received.emit(target, data.get("timestamp", 0))
