extends BTAction
class_name BTActionRangedAttack
## Ranged attack - shoot arrow at predicted player position

@export var arrow_scene_path: String = ""
@export var arrow_speed_var: StringName = &"arrow_speed"

func _tick(_delta: float) -> Status:
	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var can_attack = agent.get("can_attack")
	if not can_attack:
		return FAILURE
	
	var arrow_scene = agent.get("arrow_scene")
	if arrow_scene == null:
		return FAILURE
	
	# Start attack animation
	var animated_sprite = agent.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play("attack")
	
	agent.is_attacking = true
	agent.can_attack = false
	
	# Calculate predicted position
	var predicted_pos = _predict_player_position(player)
	var direction = (predicted_pos - agent.global_position).normalized()
	
	# Spawn arrow
	var arrow = arrow_scene.instantiate()
	agent.get_tree().current_scene.add_child(arrow)
	arrow.global_position = agent.global_position
	arrow.direction = direction
	arrow.speed = blackboard.get_var(arrow_speed_var, 200.0)
	arrow.rotation = direction.angle()
	
	# Start cooldown
	var cooldown_timer = agent.get_node_or_null("AttackCooldownTimer")
	if cooldown_timer:
		cooldown_timer.start()
	
	agent.is_attacking = false
	return SUCCESS


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
