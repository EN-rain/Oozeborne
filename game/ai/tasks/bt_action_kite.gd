extends BTAction
class_name BTActionKite
## Keep distance from player - kite behavior for archers

@export var speed_var: StringName = &"speed"
@export var ideal_distance_var: StringName = &"attack_distance"
@export var min_distance_var: StringName = &"stop_distance"

func _tick(_delta: float) -> Status:
	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var speed: float = blackboard.get_var(speed_var, 120.0)
	var ideal_distance: float = blackboard.get_var(ideal_distance_var, 150.0)
	var min_distance: float = blackboard.get_var(min_distance_var, 120.0)
	
	var distance: float = agent.global_position.distance_to(player.global_position)
	var direction: Vector2 = (player.global_position - agent.global_position).normalized()
	
	# Too close - move away
	if distance < min_distance:
		agent.velocity = -direction * speed
	# Too far - move closer
	elif distance > ideal_distance:
		agent.velocity = direction * speed
	# Perfect distance - stay still
	else:
		agent.velocity = Vector2.ZERO
	
	# Face the player
	var animated_sprite = agent.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0
		if agent.velocity != Vector2.ZERO:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
	
	return RUNNING
