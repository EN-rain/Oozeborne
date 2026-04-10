extends BTCondition
class_name BTConditionPhase

const BTBossScript := preload("res://scripts/entities/enemies/boss_behavior_tree/void_warden/bt_boss_base.gd")

## Check if boss is in required phase

@export var min_phase: int = 1


func _tick(_p_delta: float) -> Status:
	var boss: BTBossScript = agent
	if boss == null:
		return Status.FAILURE
	
	if boss.get_current_phase() >= min_phase:
		return Status.SUCCESS
	return Status.FAILURE
