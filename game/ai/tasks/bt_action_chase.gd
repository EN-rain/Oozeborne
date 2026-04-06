extends BTAction
class_name BTActionChase
## Chase the player - move towards them

@export var speed_var: StringName = &"speed"
@export var stop_distance_var: StringName = &"stop_distance"

func _tick(_delta: float) -> Status:
	if agent.get("is_attacking"):
		agent.velocity = Vector2.ZERO
		return RUNNING

	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var speed: float = blackboard.get_var(speed_var, 60.0)
	var stop_distance: float = blackboard.get_var(stop_distance_var, 10.0)
	
	var direction: Vector2 = (player.global_position - agent.global_position).normalized()
	var distance: float = agent.global_position.distance_to(player.global_position)
	
	if distance <= stop_distance:
		agent.velocity = Vector2.ZERO
		return SUCCESS
	
	# Move towards player
	agent.velocity = direction * speed
	
	# Flip sprite based on direction
	var animated_sprite = agent.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0
		animated_sprite.play("walk")
	
	return RUNNING
