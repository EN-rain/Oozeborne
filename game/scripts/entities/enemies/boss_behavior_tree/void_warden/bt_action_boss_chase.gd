extends BTAction
class_name BTActionBossChase

const BTBossScript := preload("res://scripts/entities/enemies/boss_behavior_tree/void_warden/bt_boss_base.gd")

## Boss chase - slower but more deliberate movement

@export var chase_speed_multiplier: float = 1.0


func _tick(_p_delta: float) -> Status:
	var boss: BTBossScript = agent
	if boss == null or boss.player == null:
		return Status.FAILURE
	
	var target_pos := boss.player.global_position
	var direction := (target_pos - boss.global_position).normalized()
	
	var chase_speed := boss.speed * chase_speed_multiplier
	boss.velocity = direction * chase_speed
	
	var dist := boss.global_position.distance_to(target_pos)
	if dist > boss.stop_distance:
		boss.move_and_slide()
		return Status.RUNNING
	
	return Status.SUCCESS
