extends Node
## NetworkMessaging - Handles sending and receiving network messages
## Autoload this script for network communication utilities

## Op codes for authoritative match
const OP_MESSAGE = 0      ## Generic JSON message (broadcast/custom)
const OP_INPUT = 1        ## Client -> Server: input state
const OP_STATE = 2        ## Server -> Client: state snapshot
const OP_PLAYER_JOIN = 3  ## Server -> Client: player joined
const OP_PLAYER_LEAVE = 4 ## Server -> Client: player left
const OP_START_GAME = 5   ## Host -> Server -> Clients: start game

## Ping tracking
var _last_ping_time: float = 0.0


# === PUBLIC API ===

## Get monotonic time in seconds
func now_sec() -> float:
	return Time.get_ticks_usec() / 1000000.0


## Check if sender is the local player
func is_local_player(sender_id: String) -> bool:
	if MultiplayerManager.session == null:
		return false
	return sender_id == MultiplayerManager.session.user_id


## Extract sender_id from match state
func extract_sender_id(match_state) -> String:
	if match_state.presence != null:
		return match_state.presence.user_id
	return ""


## Extract user_id from message data (for broadcast echoes)
func extract_user_id_from_data(data: Dictionary) -> String:
	return data.get("user_id", "")


## Send input to authoritative server
func send_input(move_x: float, move_y: float, is_attacking: bool = false, 
		facing: int = 1, is_dashing: bool = false, attack_rotation: float = 0.0) -> void:
	if not MultiplayerManager.is_socket_open() or MultiplayerManager.match_id.is_empty():
		return
	
	var seq = ClientPrediction.next_sequence()
	
	var input_data = {
		"move_x": move_x,
		"move_y": move_y,
		"is_attacking": is_attacking,
		"facing": facing,
		"is_dashing": is_dashing,
		"attack_rotation": attack_rotation,
		"seq": seq
	}
	
	# Store pending input for reconciliation
	ClientPrediction.store_pending_input(move_x, move_y)
	
	# Send with op code 1
	var json = JSON.stringify(input_data)
	MultiplayerManager.socket.send_match_state_async(
		MultiplayerManager.match_id, 
		OP_INPUT, 
		json, 
		null
	)


## Send attack event to server for validation and broadcast
func send_attack(pos: Vector2, rotation_angle: float, attack_seq: int = 0) -> void:
	if MultiplayerManager.session == null:
		return
	MultiplayerManager.send_match_state({
		"type": "player_attack",
		"user_id": MultiplayerManager.session.user_id,
		"attack_x": pos.x,
		"attack_y": pos.y,
		"attack_rotation": rotation_angle,
		"attack_seq": attack_seq
	})


## Send player info when joining a match
func send_player_info(ign: String, is_host: bool) -> void:
	if MultiplayerManager.session == null:
		return
	MultiplayerManager.send_match_state({
		"type": "player_info",
		"user_id": MultiplayerManager.session.user_id,
		"ign": ign,
		"is_host": is_host,
		"slime_variant": MultiplayerManager.player_slime_variant
	})


## Send ping request
func send_ping(target_user_id: String) -> void:
	MultiplayerManager.send_match_state({
		"type": "ping",
		"timestamp": now_sec(),
		"target": target_user_id
	})


## Send pong response
func send_pong(target_user_id: String, timestamp: float) -> void:
	MultiplayerManager.send_match_state({
		"type": "pong",
		"timestamp": timestamp,
		"target": target_user_id
	})


func send_skill_stat_update(stats: Dictionary) -> void:
	if MultiplayerManager.session == null:
		return
	MultiplayerManager.send_match_state({
		"type": "skill_stat_update",
		"user_id": MultiplayerManager.session.user_id,
		"stats": stats,
	})


## Calculate ping from pong response
func calculate_ping(sent_timestamp: float) -> float:
	return now_sec() - sent_timestamp


## Get current ping time
func get_ping() -> float:
	return _last_ping_time


## Set ping time
func set_ping(ping_time: float) -> void:
	_last_ping_time = ping_time
