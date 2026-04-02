extends BTAction
class_name BTActionIdle
## Play idle animation and stop movement

func _tick(_delta: float) -> Status:
	agent.velocity = Vector2.ZERO
	
	var animated_sprite = agent.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.play("idle")
	
	return SUCCESS
