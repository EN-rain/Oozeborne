extends BTAction
class_name BTActionDetectPlayer
## Detect player in detection area and set as target

const DEBUG_DETECTION := false

func _tick(_delta: float) -> Status:
	var detection_area = agent.get_node_or_null("DetectionArea")
	if detection_area == null:
		return FAILURE

	# If we already have a target and they're still in range, keep them.
	# This prevents target swapping when multiple players overlap the area.
	var current_target: Variant = agent.get("player")
	if current_target != null and is_instance_valid(current_target):
		if agent.has_method("is_targetable_player") and agent.is_targetable_player(current_target):
			if detection_area.overlaps_body(current_target):
				return SUCCESS

	# Check for overlapping bodies in player group
	var bodies = detection_area.get_overlapping_bodies()
	if DEBUG_DETECTION and Engine.get_physics_frames() % 30 == 0:
		print("[DetectPlayer] overlaps=%d agent=%s" % [bodies.size(), agent.name])
	for body in bodies:
		if agent.has_method("is_targetable_player") and agent.is_targetable_player(body):
			agent.player = body
			return SUCCESS

	# Fallback: distance-based detection (helps when collision layers/masks are misconfigured).
	var radius := _get_detection_radius(detection_area)
	if radius <= 0.0:
		agent.player = null
		return FAILURE

	var player_group: StringName = &"player"
	if agent != null and ("player_group_name" in agent):
		player_group = agent.get("player_group_name")

	var candidates := agent.get_tree().get_nodes_in_group(player_group) if agent != null and agent.get_tree() != null else []
	for candidate in candidates:
		if not (candidate is Node2D):
			continue
		if agent.has_method("is_targetable_player") and agent.is_targetable_player(candidate):
			var dist: float = agent.global_position.distance_to((candidate as Node2D).global_position)
			if dist <= radius:
				agent.player = candidate
				return SUCCESS
	
	# No player found
	agent.player = null
	return FAILURE


func _get_detection_radius(area: Area2D) -> float:
	if area == null:
		return 0.0

	for child in area.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null or shape_node.disabled or shape_node.shape == null:
			continue
		var shape := shape_node.shape
		var scale_factor := maxf(absf(area.global_scale.x), absf(area.global_scale.y))
		if shape is CircleShape2D:
			return (shape as CircleShape2D).radius * scale_factor
		if shape is RectangleShape2D:
			var rect := shape as RectangleShape2D
			return rect.size.length() * 0.5 * scale_factor
		if shape is CapsuleShape2D:
			var cap := shape as CapsuleShape2D
			return (cap.height * 0.5 + cap.radius) * scale_factor

	return 0.0
