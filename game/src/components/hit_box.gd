extends Area2D

@export var enemy_group_name: StringName = &"enemies"


func _on_body_entered(body):
	if body.is_in_group(enemy_group_name):
		body.take_damage(10)
