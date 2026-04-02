extends Node2D

var can_slash: bool = true

@export var slash_time: float = 0.2
@export var sword_return_time: float = 0.5
@export var weapon_damage: float = 1

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("basic_attack") and can_slash:
		$SwordAnim.speed_scale = $SwordSprite
		$SwordAnim.play("basic_attack")
		can_slash = false
		
const sword_slash_preload = preload("res://scenes/entities/player/slash.tscn")
func spawn_slash():
	var sword_slash_var = sword_slash_preload.instantiate()
	sword_slash_var.get_node("$SwordSprite/SwordAnim").speed_scale = sword_slash_var.get_node("$SwordSprite/SwordAnim").get_animation("basic_attack").length / slash_time 
	sword_slash_var.get_node("$SwordSprite").flip_v = false if get_global_mouse_position().x > global_position.x else true
	sword_slash_var.weapon_damage = weapon_damage
	get_parent().add_child(sword_slash_var)
	
func _on_sword_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "basic_attack":
		$SwordAnim.speed_scale = $SwordSprite/SwordAnim.get_animation("sword_return").length / slash_time
		$SwordAnim.play("basic_attack")
	else:
		can_slash = true
