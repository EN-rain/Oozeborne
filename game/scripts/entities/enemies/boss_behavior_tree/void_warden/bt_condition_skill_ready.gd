extends BTCondition
class_name BTConditionSkillReady

const BTBossScript := preload("res://scripts/entities/enemies/boss_behavior_tree/void_warden/bt_boss_base.gd")

## Check if a specific skill is ready

@export var skill_name: String = ""


func _tick(_p_delta: float) -> Status:
	var boss: BTBossScript = agent
	if boss == null or skill_name.is_empty():
		return Status.FAILURE
	
	if boss.is_skill_ready(skill_name):
		return Status.SUCCESS
	return Status.FAILURE
