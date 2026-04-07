extends BTAction
class_name BTActionIdle
## Play idle animation and roam when no player target

var _idle_move_timer: float = 0.0
var _idle_target: Vector2 = Vector2.ZERO
var _has_idle_target: bool = false

func _tick(delta: float) -> Status:
	if agent.get("is_attacking"):
		agent.velocity = Vector2.ZERO
		return RUNNING
	
	# Check if player is detected - if so, let other BT nodes handle
	var player = agent.get("player")
	var animated_sprite = agent.get_node_or_null("AnimatedSprite2D")
	if player != null:
		_has_idle_target = false
		agent.velocity = Vector2.ZERO
		if animated_sprite:
			animated_sprite.play("idle")
		return SUCCESS
	
	# Idle roaming logic
	_idle_move_timer -= delta
	
	if _idle_move_timer <= 0.0:
		_pick_idle_target()
	
	if _has_idle_target:
		var idle_direction: Vector2 = _idle_target - agent.global_position
		if idle_direction.length() > 6.0:
			var speed = agent.get("speed") if agent.has_method("get") else 60.0
			var idle_move_speed_multiplier = agent.get("idle_move_speed_multiplier") if agent.has_method("get") else 0.45
			agent.velocity = idle_direction.normalized() * speed * idle_move_speed_multiplier
		else:
			agent.velocity = Vector2.ZERO
			_has_idle_target = false
	else:
		agent.velocity = Vector2.ZERO
	
	if animated_sprite:
		if agent.velocity.length() > 1.0:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
	
	return SUCCESS

func _pick_idle_target() -> void:
	var idle_move_interval = agent.get("idle_move_interval") if agent.has_method("get") else 3.0
	var idle_move_radius = agent.get("idle_move_radius") if agent.has_method("get") else 64.0
	
	_idle_move_timer = idle_move_interval
	var random_offset := Vector2(
		randf_range(-idle_move_radius, idle_move_radius),
		randf_range(-idle_move_radius, idle_move_radius)
	)
	if random_offset.length() < 8.0:
		random_offset = Vector2.RIGHT.rotated(randf() * TAU) * 16.0
	_idle_target = agent.global_position + random_offset
	_has_idle_target = true
