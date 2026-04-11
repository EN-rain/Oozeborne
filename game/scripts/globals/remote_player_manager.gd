extends Node
## RemotePlayerManager - Handles remote player tracking, interpolation, and state
## Autoload this script to manage remote players from any scene

## Remote player data with position buffering and extrapolation
## { user_id: { "node": Player, "positions": [{pos, timestamp, velocity}], 
##   "velocity": Vector2, "smooth_velocity": Vector2, "is_visible": bool } }
var _remote_players: Dictionary = {}

## Network quality adaptation
var _jitter_samples: Array = []
var _adaptive_interpolation_delay: float = 0.07

## Constants
const MIN_INTERPOLATION_DELAY: float = 0.05
const MAX_INTERPOLATION_DELAY: float = 0.12
const POSITION_BUFFER_SIZE: int = 20
const SMOOTH_DAMP_MAX_SPEED: float = 800.0


## Get monotonic time in seconds
func _now_sec() -> float:
	return Time.get_ticks_usec() / 1000000.0


# === PUBLIC API ===

## Register a remote player for interpolation
func register_player(user_id: String, player_node: Node, initial_pos: Vector2) -> void:
	var timestamp = _now_sec()
	_remote_players[user_id] = {
		"node": player_node,
		"positions": [{"pos": initial_pos, "timestamp": timestamp, "velocity": Vector2.ZERO}],
		"velocity": Vector2.ZERO,
		"smooth_velocity": Vector2.ZERO,
		"is_visible": false,
		"last_update_time": timestamp,
		"render_time_offset": _adaptive_interpolation_delay,
		"server_facing": 1,
		"server_velocity": Vector2.ZERO,
		"is_attacking": false,
		"is_dashing": false,
		"pending_attack": null
	}


## Unregister a remote player
func unregister_player(user_id: String) -> void:
	if _remote_players.has(user_id):
		_remote_players.erase(user_id)


## Check if a user_id is a tracked remote player
func has_player(user_id: String) -> bool:
	return _remote_players.has(user_id)


## Get all tracked remote players
func get_players() -> Dictionary:
	return _remote_players


## Get remote player node by user_id
func get_player_node(user_id: String) -> Node:
	if _remote_players.has(user_id):
		return _remote_players[user_id].node
	return null


## Check if remote player is visible (has received first position)
func is_player_visible(user_id: String) -> bool:
	if _remote_players.has(user_id):
		return _remote_players[user_id].is_visible
	return false


## Update target position for a remote player with velocity
func update_player_target(user_id: String, target_pos: Vector2, velocity: Vector2, 
		facing: int, is_attacking: bool = false, is_dashing: bool = false, 
		attack_rotation: float = 0.0) -> void:
	if not _remote_players.has(user_id):
		push_warning("[RemotePlayerManager] No remote player found for user_id: " + user_id)
		return
	
	var player_data = _remote_players[user_id]
	var receive_time = _now_sec()
	
	# Track jitter
	var time_since_last = receive_time - player_data.last_update_time
	_track_jitter(time_since_last)
	
	# Add to position buffer
	player_data.positions.append({
		"pos": target_pos, 
		"timestamp": receive_time, 
		"velocity": velocity
	})
	
	# Trim buffer
	while player_data.positions.size() > POSITION_BUFFER_SIZE:
		player_data.positions.pop_front()
	
	player_data.velocity = velocity
	player_data.last_update_time = receive_time
	player_data.is_visible = true
	player_data.render_time_offset = _adaptive_interpolation_delay
	player_data.server_facing = facing
	player_data.server_velocity = velocity
	
	# Track attack state change (edge detection)
	var was_attacking = player_data.is_attacking
	player_data.is_attacking = is_attacking
	player_data.is_dashing = is_dashing
	
	# Trigger attack on rising edge
	if is_attacking and not was_attacking:
		_trigger_attack(player_data, attack_rotation)
	
	# Handle dash visual effect
	_update_dash_visuals(player_data, is_dashing)


## Interpolate all remote players
func interpolate_players(delta: float) -> void:
	var now = _now_sec()
	
	for user_id in _remote_players:
		var player_data = _remote_players[user_id]
		var node = player_data.node
		
		if not is_instance_valid(node) or not player_data.is_visible:
			continue
		
		var positions = player_data.positions
		if positions.is_empty():
			continue
		
		var render_time = now - player_data.render_time_offset
		var target_pos = _get_interpolated_position(positions, render_time)
		var dist_to_target = node.global_position.distance_to(target_pos)
		
		# Hard snap for large desync
		if dist_to_target > 220.0:
			node.global_position = target_pos
			player_data.smooth_velocity = Vector2.ZERO
			continue
		
		# Smooth damp
		var result = _smooth_damp(
			node.global_position,
			target_pos,
			player_data.smooth_velocity,
			0.06,
			delta
		)
		
		node.global_position = result.pos
		player_data.smooth_velocity = result.vel
		
		# Update animation
		_update_player_animation(player_data, node)


## Get and clear pending attack for a remote player
func get_pending_attack(user_id: String) -> Dictionary:
	if not _remote_players.has(user_id):
		return {}
	var player_data = _remote_players[user_id]
	if player_data.has("pending_attack") and player_data.pending_attack != null:
		var attack = player_data.pending_attack
		player_data.pending_attack = null
		return attack
	return {}


## Get current adaptive interpolation delay
func get_interpolation_delay() -> float:
	return _adaptive_interpolation_delay


# === INTERNAL HELPERS ===

func _trigger_attack(player_data: Dictionary, attack_rotation: float) -> void:
	player_data.pending_attack = {
		"pos": player_data.node.global_position, 
		"rotation": attack_rotation
	}


func _update_dash_visuals(player_data: Dictionary, is_dashing: bool) -> void:
	var dash_particles = player_data.node.get_node_or_null("DashParticles")
	var dash_trail = player_data.node.get_node_or_null("DashTrail")
	var sprite = player_data.node.get_node_or_null("AnimatedSprite2D")
	
	if is_dashing:
		# Set particle direction based on velocity (like solo play)
		var dash_vel = player_data.server_velocity if player_data.server_velocity.length() > 1.0 else Vector2(player_data.server_facing, 0)
		var angle = dash_vel.angle()
		if dash_particles:
			dash_particles.direction = Vector2(cos(angle), sin(angle))
			if not dash_particles.emitting:
				dash_particles.emitting = true
		if dash_trail:
			dash_trail.direction = Vector2(cos(angle), sin(angle))
			if not dash_trail.emitting:
				dash_trail.emitting = true
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.5)
	else:
		if dash_particles:
			dash_particles.emitting = false
		if dash_trail:
			dash_trail.emitting = false
		if sprite:
			sprite.modulate = Color.WHITE


func _update_player_animation(player_data: Dictionary, node: Node) -> void:
	var sprite = node.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	
	sprite.flip_h = player_data.server_facing > 0
	
	if player_data.is_dashing:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("dash"):
			if sprite.animation != "dash":
				sprite.play("dash")
		return
	# Attack visual is the slash effect, not a sprite animation
	# Keep current animation during attack (idle or walk)
	if player_data.is_attacking:
		return
	if player_data.server_velocity.length() > 5.0:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")


func _smooth_damp(current: Vector2, target: Vector2, velocity: Vector2, 
		smooth_time: float, delta: float) -> Dictionary:
	var omega = 2.0 / smooth_time
	var x = omega * delta
	var smoothing_factor = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	var change = current - target
	var max_change = SMOOTH_DAMP_MAX_SPEED * smooth_time
	var max_change_sq = max_change * max_change
	
	var sq_len = change.length_squared()
	if sq_len > max_change_sq:
		var mag = sqrt(sq_len)
		change = change / mag * max_change
	
	var temp = (velocity + omega * change) * delta
	var new_velocity = (velocity - omega * temp) * smoothing_factor
	var new_pos = current - (change + temp) * smoothing_factor
	
	if (target - current).dot(new_pos - target) > 0:
		new_pos = target
		new_velocity = Vector2.ZERO
	
	return {"pos": new_pos, "vel": new_velocity}


func _get_interpolated_position(positions: Array, render_time: float) -> Vector2:
	if positions.is_empty():
		return Vector2.ZERO
	
	if positions.size() == 1:
		return positions[0].pos
	
	var older_idx = -1
	for i in range(positions.size() - 1, -1, -1):
		if positions[i].timestamp <= render_time:
			older_idx = i
			break
	
	if older_idx < 0:
		return positions[0].pos
	
	if older_idx >= positions.size() - 1:
		return positions[-1].pos
	
	var older = positions[older_idx]
	var newer = positions[older_idx + 1]
	
	var time_span = newer.timestamp - older.timestamp
	if time_span < 0.001:
		return older.pos
	
	var t = clamp((render_time - older.timestamp) / time_span, 0.0, 1.0)
	return older.pos.lerp(newer.pos, t)


func _track_jitter(time_since_last: float) -> void:
	_jitter_samples.append(time_since_last)
	if _jitter_samples.size() > 20:
		_jitter_samples.pop_front()
	
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
		_adaptive_interpolation_delay = clamp(
			jitter * 3.0,
			MIN_INTERPOLATION_DELAY,
			MAX_INTERPOLATION_DELAY
		)
