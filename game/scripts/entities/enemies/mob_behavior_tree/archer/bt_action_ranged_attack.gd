extends BTAction
class_name BTActionRangedAttack
## Ranged attack - shoot arrow at predicted player position

@export var arrow_scene_path: String = ""
@export var arrow_speed_var: StringName = &"arrow_speed"

func _tick(_delta: float) -> Status:
	if agent.get("is_attacking"):
		return RUNNING

	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var can_attack = agent.get("can_attack")
	if not can_attack:
		return FAILURE
	
	var arrow_scene = agent.get("arrow_scene")
	if arrow_scene == null:
		return FAILURE
	
	# Calculate predicted position
	var predicted_pos = _predict_player_position(player)
	var direction = (predicted_pos - agent.global_position).normalized()
	var projectile_speed: float = blackboard.get_var(arrow_speed_var, 200.0)

	if agent.has_method("begin_ranged_attack") and agent.begin_ranged_attack(direction, projectile_speed):
		return RUNNING

	return FAILURE


func _predict_player_position(player: Node) -> Vector2:
	var samples = agent.get("player_velocity_samples")
	if samples == null or samples.is_empty():
		return player.global_position
	
	# Calculate average velocity
	var total: Vector2 = Vector2.ZERO
	for sample in samples:
		total += sample
	var avg_velocity: Vector2 = total / float(samples.size())
	
	# Predict future position
	var distance: float = agent.global_position.distance_to(player.global_position)
	var arrow_speed: float = blackboard.get_var(arrow_speed_var, 200.0)
	var time_to_hit: float = distance / arrow_speed
	
	return player.global_position + (avg_velocity * time_to_hit * 60)
