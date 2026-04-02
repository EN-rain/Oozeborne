extends BTAction
## Teleport behind the player (for Lancer)

@export var teleport_distance_var: StringName = &"teleport_distance"
@export var cooldown_var: StringName = &"blink_cooldown"

func _tick(_delta: float) -> Status:
	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var can_blink = agent.get("can_blink")
	if not can_blink:
		return FAILURE
	
	var is_teleporting = agent.get("is_teleporting")
	if is_teleporting:
		return RUNNING
	
	# Start teleport
	agent.is_teleporting = true
	agent.can_blink = false
	agent.velocity = Vector2.ZERO
	
	# Get player facing direction
	var player_facing = Vector2.RIGHT
	if player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D")
		if player_sprite.flip_h:
			player_facing = Vector2.LEFT
	
	# Calculate position behind player
	var teleport_distance: float = blackboard.get_var(teleport_distance_var, 10.0)
	var behind_position = player.global_position - (player_facing * teleport_distance)
	
	# Play teleport effect
	var teleport_particles = agent.get_node_or_null("TeleportParticles")
	if teleport_particles:
		teleport_particles.emitting = true
	
	# Fade out
	var animated_sprite = agent.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		var tween = agent.create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	# Teleport
	agent.global_position = behind_position
	
	# Fade in
	if teleport_particles:
		teleport_particles.emitting = true
	if animated_sprite:
		var tween = agent.create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.3)
		await tween.finished
	
	agent.is_teleporting = false
	
	# Start cooldown
	var cooldown_timer = agent.get_node_or_null("BlinkCooldownTimer")
	if cooldown_timer:
		cooldown_timer.start()
	
	return SUCCESS
