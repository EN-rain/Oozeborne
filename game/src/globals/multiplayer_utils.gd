extends Node
## MultiplayerUtils - Reusable multiplayer functions for Nakama-based games
## Autoload this script to access multiplayer utilities from any scene

## Op codes for authoritative match
const OP_INPUT = 1        ## Client -> Server: input state
const OP_STATE = 2        ## Server -> Client: state snapshot
const OP_PLAYER_JOIN = 3  ## Server -> Client: player joined
const OP_PLAYER_LEAVE = 4 ## Server -> Client: player left
const OP_START_GAME = 5   ## Host -> Server -> Clients: start game

## Remote player data with position buffering and extrapolation
## { user_id: { "node": Player, "positions": [{pos, timestamp, velocity}], 
##   "velocity": Vector2, "smooth_velocity": Vector2, "is_visible": bool } }
var _remote_players: Dictionary = {}

## Input sequence for authoritative sync
var _input_sequence: int = 0

## Client-side prediction: pending inputs awaiting server acknowledgment
## Stores inputs that haven't been confirmed by server yet
var _pending_inputs: Array = []  # [{seq, move_x, move_y, timestamp}]
const MAX_PENDING_INPUTS: int = 60  # Keep last 60 inputs (3 seconds at 20Hz)

## Local player reference for reconciliation
var _local_player_node: WeakRef = WeakRef.new()

var _reconciliation_threshold: float = 15.0  # Snap if desync > 15 pixels

## Prediction enabled flag
var _prediction_enabled: bool = true

## Get monotonic time in seconds (avoids wall-clock issues)
func _now_sec() -> float:
	return Time.get_ticks_usec() / 1000000.0

# Ping tracking
var _last_ping_time: float = 0.0

var _jitter_samples: Array = []  # Store recent update intervals
var _adaptive_interpolation_delay: float = 0.07  # 70ms for smooth interpolation
const MIN_INTERPOLATION_DELAY: float = 0.05  # 50ms minimum
const MAX_INTERPOLATION_DELAY: float = 0.12   # 120ms maximum
const POSITION_BUFFER_SIZE: int = 20  # Store last 20 positions for better buffering
const SMOOTH_DAMP_MAX_SPEED: float = 800.0  # Max interpolation speed
const EXTRAPOLATION_MAX_TIME: float = 0.15  # Don't extrapolate more than 150ms


## Initialize a remote player entry for interpolation
func register_remote_player(user_id: String, player_node: Node, initial_pos: Vector2, start_visible: bool = false) -> void:
	var timestamp = _now_sec()
	_remote_players[user_id] = {
		"node": player_node,
		"positions": [{"pos": initial_pos, "timestamp": timestamp, "velocity": Vector2.ZERO}],
		"velocity": Vector2.ZERO,
		"smooth_velocity": Vector2.ZERO,  # For smooth damp
		"is_visible": start_visible,
		"last_update_time": timestamp,
		"render_time_offset": _adaptive_interpolation_delay,
		"server_facing": 1,  # Track server-facing direction
		"server_velocity": Vector2.ZERO,  # Track server velocity for animation
		"is_attacking": false,  # Track attack state
		"is_dashing": false,  # Track dash state
		"pending_attack": null  # Pending attack info for slash spawning
	}


## Remove a remote player from tracking
func unregister_remote_player(user_id: String) -> void:
	if _remote_players.has(user_id):
		_remote_players.erase(user_id)


## Update target position for a remote player with velocity
func update_remote_player_target(user_id: String, target_pos: Vector2, velocity: Vector2, facing: int, is_attacking: bool = false, is_dashing: bool = false, attack_rotation: float = 0.0) -> void:
	if not _remote_players.has(user_id):
		print("[MultiplayerUtils] WARNING: No remote player found for user_id: ", user_id)
		return
	
	var player_data = _remote_players[user_id]
	var receive_time = _now_sec()
	
	# Track jitter (time since last update)
	var time_since_last = receive_time - player_data.last_update_time
	_track_jitter(time_since_last)
	
	# Debug: Log position updates rarely (every 50th)
	if player_data.positions.size() % 50 == 0:
		print("[MultiplayerUtils] Pos update for ", user_id.substr(0,8), ": ", target_pos, " vel: ", velocity, " facing: ", facing, " interval: ", snapped(time_since_last, 0.001))
	
	# Add to position buffer with receive timestamp
	player_data.positions.append({
		"pos": target_pos, 
		"timestamp": receive_time, 
		"velocity": velocity
	})
	
	# Trim buffer to max size
	while player_data.positions.size() > POSITION_BUFFER_SIZE:
		player_data.positions.pop_front()
	
	player_data.velocity = velocity
	player_data.last_update_time = receive_time
	player_data.is_visible = true
	player_data.render_time_offset = _adaptive_interpolation_delay
	player_data.server_facing = facing  # Store server-facing direction
	player_data.server_velocity = velocity  # Store server velocity for animation
	
	# Track attack state change (edge detection)
	var was_attacking = player_data.is_attacking
	player_data.is_attacking = is_attacking
	
	# Track dash state
	player_data.is_dashing = is_dashing
	
	# Only trigger attack animation on rising edge (was false, now true)
	if is_attacking and not was_attacking:
		print("[MultiplayerUtils] Attack detected for remote player at ", player_data.node.global_position)
		# Store attack info using player's VISUAL position and attack rotation
		player_data.pending_attack = {"pos": player_data.node.global_position, "rotation": attack_rotation}
	
	# Handle dash visual effect
	var dash_particles = player_data.node.get_node_or_null("DashParticles")
	if is_dashing:
		if dash_particles and not dash_particles.emitting:
			dash_particles.emitting = true
		var sprite = player_data.node.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.5)
	else:
		if dash_particles:
			dash_particles.emitting = false
		var sprite = player_data.node.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.modulate = Color.WHITE


## Interpolate all remote players using buffered timeline interpolation
## Call this from _process(delta) in your main game scene
func interpolate_remote_players(delta: float, _lerp_speed: float = 8.0) -> void:
	var now = _now_sec()
	
	for user_id in _remote_players:
		var player_data = _remote_players[user_id]
		var node = player_data.node
		
		if not is_instance_valid(node):
			continue
		
		# Skip if not visible yet (waiting for first position)
		if not player_data.is_visible:
			continue
		
		var positions = player_data.positions
		if positions.is_empty():
			continue
		
		# Render slightly in the past for smoothness (buffered interpolation)
		var render_time = now - player_data.render_time_offset
		var target_pos = _get_interpolated_position(positions, render_time, player_data)
		
		# Calculate distance to target
		var dist_to_target = node.global_position.distance_to(target_pos)
		
		# Only hard snap for very large desync (raised from 100 to 220)
		if dist_to_target > 220.0:
			_move_remote_node_with_collisions(node, target_pos)
			player_data.smooth_velocity = Vector2.ZERO
		else:
			# Apply smooth damp (critically damped spring) - faster for tighter sync
			var result = _smooth_damp(
				node.global_position,
				target_pos,
				player_data.smooth_velocity,
				0.06,  # Faster response for less drift
				delta
			)
			
			_move_remote_node_with_collisions(node, result.pos)
			player_data.smooth_velocity = result.vel
		
		# Update facing direction and animation based on SERVER state
		var sprite = node.get_node_or_null("AnimatedSprite2D")
		if sprite:
			# Use server-facing direction for sprite flip
			sprite.flip_h = player_data.server_facing < 0
			
			_update_remote_player_animation(sprite, player_data.server_velocity, player_data.is_attacking)


## Extract sender_id from match state, handling broadcast echoes
func extract_sender_id(match_state) -> String:
	var sender_id = ""
	if match_state.presence != null:
		sender_id = match_state.presence.user_id
	return sender_id


## Extract user_id from message data (for broadcast echoes with empty sender_id)
func extract_user_id_from_data(data: Dictionary) -> String:
	return data.get("user_id", "")


## Check if sender is the local player
func is_local_player(sender_id: String) -> bool:
	if MultiplayerManager.session == null:
		return false
	return sender_id == MultiplayerManager.session.user_id


## Send attack event to all other players
func send_attack(pos: Vector2, rotation_angle: float) -> void:
	if MultiplayerManager.session == null:
		return  # Not in multiplayer
	MultiplayerManager.send_match_state({
		"type": "player_attack",
		"user_id": MultiplayerManager.session.user_id,
		"pos": {"x": pos.x, "y": pos.y},
		"rot": rotation_angle
	})


## Send player info when joining a match
func send_player_info(ign: String, is_host: bool) -> void:
	if MultiplayerManager.session == null:
		return  # Not in multiplayer
	MultiplayerManager.send_match_state({
		"type": "player_info",
		"user_id": MultiplayerManager.session.user_id,
		"ign": ign,
		"is_host": is_host
	})


## Set local player node for prediction/reconciliation
func set_local_player(player_node: Node) -> void:
	_local_player_node = weakref(player_node)

## Send input to authoritative server (replaces send_position)
func send_input(move_x: float, move_y: float, is_attacking: bool = false, facing: int = 1, is_dashing: bool = false, attack_rotation: float = 0.0) -> void:
	if not MultiplayerManager.is_socket_open() or MultiplayerManager.match_id.is_empty():
		return
	
	_input_sequence += 1
	
	var input_data = {
		"move_x": move_x,
		"move_y": move_y,
		"is_attacking": is_attacking,
		"facing": facing,
		"is_dashing": is_dashing,
		"attack_rotation": attack_rotation,
		"seq": _input_sequence
	}
	
	# Store pending input for reconciliation
	_pending_inputs.append({
		"seq": _input_sequence,
		"move_x": move_x,
		"move_y": move_y,
		"timestamp": _now_sec()
	})
	
	# Trim old inputs
	while _pending_inputs.size() > MAX_PENDING_INPUTS:
		_pending_inputs.pop_front()
	
	# Send with op code 1 (OP_INPUT) directly to server
	var json = JSON.stringify(input_data)
	MultiplayerManager.socket.send_match_state_async(
		MultiplayerManager.match_id, 
		OP_INPUT, 
		json, 
		null  # null = send to server only
	)


## Start input update loop - sends input at 20Hz to match server tickrate
func start_input_update_loop(player_node: Node) -> void:
	_send_input_updates(player_node)


func _send_input_updates(player_node: Node) -> void:
	print("[MultiplayerUtils] Starting input updates at 20Hz (authoritative)")
	const INPUT_RATE: float = 0.05  # 20Hz to match server tickrate
	
	while true:
		# Check connection state first
		if not MultiplayerManager.is_socket_open() or MultiplayerManager.match_id.is_empty():
			print("[MultiplayerUtils] Stopping input updates - disconnected")
			break
		if not is_instance_valid(player_node):
			print("[MultiplayerUtils] Stopping input updates - player node invalid")
			break
		
		# Read input from the player
		var move_x := Input.get_action_strength("right") - Input.get_action_strength("left")
		var move_y := Input.get_action_strength("down") - Input.get_action_strength("up")
		
		# Get facing direction from player (based on mouse cursor)
		var facing := 1
		if player_node.get("facing") != null:
			facing = player_node.facing
		
		# Attack slash sync is event-based now, so the input stream only needs dash state.
		var is_attacking := false
		var is_dashing := false
		if player_node.get("is_dashing") != null:
			is_dashing = player_node.is_dashing
		
		# Send input to server with facing and dash state.
		if not MultiplayerManager.is_socket_open():
			print("[MultiplayerUtils] Stopping input updates - socket closed before send")
			break
		send_input(move_x, move_y, is_attacking, facing, is_dashing)
		
		# Wait for next input tick
		await Engine.get_main_loop().create_timer(INPUT_RATE).timeout


## Send ping request
func send_ping(target_user_id: String) -> void:
	MultiplayerManager.send_match_state({
		"type": "ping",
		"timestamp": _now_sec(),
		"target": target_user_id
	})


## Send pong response
func send_pong(target_user_id: String, timestamp: float) -> void:
	MultiplayerManager.send_match_state({
		"type": "pong",
		"timestamp": timestamp,
		"target": target_user_id
	})


## Calculate ping from pong response
func calculate_ping(sent_timestamp: float) -> float:
	return _now_sec() - sent_timestamp


## Get current ping time (last calculated)
func get_ping() -> float:
	return _last_ping_time


## Set ping time (called when receiving pong)
func set_ping(ping_time: float) -> void:
	_last_ping_time = ping_time


## Get all tracked remote players
func get_remote_players() -> Dictionary:
	return _remote_players


## Check if a user_id is a tracked remote player
func has_remote_player(user_id: String) -> bool:
	return _remote_players.has(user_id)


## Get remote player node by user_id
func get_remote_player_node(user_id: String) -> Node:
	if _remote_players.has(user_id):
		return _remote_players[user_id].node
	return null


## Check if remote player is visible (has received first position)
func is_remote_player_visible(user_id: String) -> bool:
	if _remote_players.has(user_id):
		return _remote_players[user_id].is_visible
	return false


# === INTERNAL HELPER FUNCTIONS ===

## Smooth damp implementation (critically damped spring)
## Returns Dictionary with {"pos": Vector2, "vel": Vector2}
func _smooth_damp(current: Vector2, target: Vector2, velocity: Vector2, smooth_time: float, delta: float) -> Dictionary:
	# Based on Unity's Mathf.SmoothDamp
	var omega = 2.0 / smooth_time
	var x = omega * delta
	var smoothing_factor = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	var change = current - target
	var max_change = SMOOTH_DAMP_MAX_SPEED * smooth_time
	var max_change_sq = max_change * max_change
	
	# Clamp magnitude
	var sq_len = change.length_squared()
	if sq_len > max_change_sq:
		var mag = sqrt(sq_len)
		change = change / mag * max_change
	
	var temp = (velocity + omega * change) * delta
	var new_velocity = (velocity - omega * temp) * smoothing_factor
	var new_pos = current - (change + temp) * smoothing_factor
	
	# Prevent overshooting
	if (target - current).dot(new_pos - target) > 0:
		new_pos = target
		new_velocity = Vector2.ZERO
	
	return {"pos": new_pos, "vel": new_velocity}


## Get interpolated position from buffer based on render time
func _get_interpolated_position(positions: Array, render_time: float, _player_state: Dictionary) -> Vector2:
	if positions.is_empty():
		return Vector2.ZERO
	
	if positions.size() == 1:
		# Only one position, use it directly (no extrapolation to prevent drift)
		return positions[0].pos
	
	# Find the two positions that bracket the render time
	# We want to interpolate between the position slightly in the past
	var older_idx = -1
	for i in range(positions.size() - 1, -1, -1):
		if positions[i].timestamp <= render_time:
			older_idx = i
			break
	
	# If render time is before all positions, use oldest (no extrapolation)
	if older_idx < 0:
		return positions[0].pos
	
	# If we're at the last position, use it directly (no extrapolation to prevent drift)
	if older_idx >= positions.size() - 1:
		return positions[-1].pos
	
	# Interpolate between older and newer positions
	var older = positions[older_idx]
	var newer = positions[older_idx + 1]
	
	var time_span = newer.timestamp - older.timestamp
	if time_span < 0.001:  # Avoid division by zero
		return older.pos
	
	var t = (render_time - older.timestamp) / time_span
	t = clamp(t, 0.0, 1.0)
	
	# Simple lerp between positions - NO velocity extrapolation to prevent drift
	return older.pos.lerp(newer.pos, t)


## Extrapolate position when no recent updates (DISABLED - returns last known position)
func _extrapolate_position(pos_data: Dictionary, _render_time: float, _player_data: Dictionary) -> Vector2:
	# Disabled extrapolation to prevent drift - just return last known position
	return pos_data.pos


## Track jitter for network quality adaptation
func _track_jitter(time_since_last: float) -> void:
	_jitter_samples.append(time_since_last)
	if _jitter_samples.size() > 20:
		_jitter_samples.pop_front()
	
	# Calculate jitter variance
	if _jitter_samples.size() >= 5:
		var mean = 0.0
		for sample in _jitter_samples:
			mean += sample
		mean /= _jitter_samples.size()
		
		var variance = 0.0
		for sample in _jitter_samples:
			variance += (sample - mean) * (sample - mean)
		variance /= _jitter_samples.size()
		
		var jitter = sqrt(variance)
		
		# Adapt interpolation delay based on jitter
		# Higher jitter = more delay for smoother playback
		_adaptive_interpolation_delay = clamp(
			jitter * 3.0,  # 3x jitter as safety margin
			MIN_INTERPOLATION_DELAY,
			MAX_INTERPOLATION_DELAY
		)


## Get current adaptive interpolation delay
func get_interpolation_delay() -> float:
	return _adaptive_interpolation_delay


## Reconcile local player with server state
## Call this when receiving server snapshot for local player
func reconcile_local_player(server_pos: Vector2, server_vel: Vector2, server_seq: int) -> void:
	if not _prediction_enabled:
		return
	
	var player_node = _local_player_node.get_ref()
	if not is_instance_valid(player_node):
		return
	
	# Remove acknowledged inputs from pending queue
	while _pending_inputs.size() > 0 and _pending_inputs[0].seq <= server_seq:
		_pending_inputs.pop_front()
	
	# Calculate position error
	var pos_error = player_node.global_position - server_pos
	var error_dist = pos_error.length()
	
	# Debug log occasionally
	if _input_sequence % 100 == 0:
		print("[Prediction] Error: ", snapped(error_dist, 0.1), " px | Pending: ", _pending_inputs.size())
	
	# Only reconcile if error exceeds threshold
	if error_dist > _reconciliation_threshold:
		# Snap to server position
		player_node.global_position = server_pos
		player_node.velocity = server_vel
		
		# Replay pending inputs to get back to predicted state
		for input in _pending_inputs:
			var dt = 1.0 / 20.0  # Server tickrate
			player_node.global_position.x += input.move_x * 100.0 * dt
			player_node.global_position.y += input.move_y * 100.0 * dt
	
## Enable/disable prediction (for debugging)
func set_prediction_enabled(enabled: bool) -> void:
	_prediction_enabled = enabled

## Get pending input count (for debugging)
func get_pending_input_count() -> int:
	return _pending_inputs.size()


## Get and clear pending attack for a remote player (for slash spawning)
func get_pending_attack(user_id: String) -> Dictionary:
	if not _remote_players.has(user_id):
		return {}
	var player_data = _remote_players[user_id]
	if player_data.has("pending_attack") and player_data.pending_attack != null:
		var attack = player_data.pending_attack
		player_data.pending_attack = null
		return attack
	return {}


func _update_remote_player_animation(sprite: AnimatedSprite2D, server_velocity: Vector2, is_attacking: bool) -> void:
	var target_animation := "walk" if server_velocity.length() > 5.0 else "idle"
	if sprite.animation != target_animation:
		sprite.play(target_animation)


func _move_remote_node_with_collisions(node: Node, target_pos: Vector2) -> void:
	if not is_instance_valid(node):
		return

	if node is CharacterBody2D:
		var body := node as CharacterBody2D
		var motion := target_pos - body.global_position
		if motion.length_squared() <= 0.0001:
			return

		var collision := body.move_and_collide(motion)
		if collision:
			var slide_motion := collision.get_remainder().slide(collision.get_normal())
			if slide_motion.length_squared() > 0.0001:
				body.move_and_collide(slide_motion)
		return

	node.global_position = target_pos
