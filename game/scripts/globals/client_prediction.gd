extends Node
## ClientPrediction - Handles client-side prediction and server reconciliation
## Autoload this script to manage prediction from any scene

## Input sequence for authoritative sync
var _input_sequence: int = 0

## Pending inputs awaiting server acknowledgment
var _pending_inputs: Array = []
const MAX_PENDING_INPUTS: int = 60

## Local player reference for reconciliation
var _local_player_node: WeakRef = WeakRef.new()

var _reconciliation_threshold: float = 15.0

## Prediction enabled flag
var _prediction_enabled: bool = true


# === PUBLIC API ===

## Set local player node for prediction/reconciliation
func set_local_player(player_node: Node) -> void:
	_local_player_node = weakref(player_node)


## Get pending input count (for debugging)
func get_pending_input_count() -> int:
	return _pending_inputs.size()


## Enable/disable prediction (for debugging)
func set_prediction_enabled(enabled: bool) -> void:
	_prediction_enabled = enabled


## Store pending input for reconciliation
func store_pending_input(move_x: float, move_y: float) -> void:
	_input_sequence += 1
	_pending_inputs.append({
		"seq": _input_sequence,
		"move_x": move_x,
		"move_y": move_y,
		"timestamp": _now_sec()
	})
	
	# Trim old inputs
	while _pending_inputs.size() > MAX_PENDING_INPUTS:
		_pending_inputs.pop_front()


## Get current input sequence
func get_input_sequence() -> int:
	return _input_sequence


## Increment and return new sequence
func next_sequence() -> int:
	_input_sequence += 1
	return _input_sequence


## Reconcile local player with server state
func reconcile(server_pos: Vector2, server_vel: Vector2, server_seq: int) -> void:
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
	
# === INTERNAL HELPERS ===

func _now_sec() -> float:
	return Time.get_ticks_usec() / 1000000.0
