extends BTCondition
class_name BTConditionCanAttack
## Check if archer can attack (cooldown ready)

func _tick(_delta: float) -> Status:
	var can_attack = agent.get("can_attack")
	if can_attack:
		return SUCCESS
	return FAILURE
