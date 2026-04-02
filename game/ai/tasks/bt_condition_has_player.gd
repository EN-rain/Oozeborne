extends BTCondition
class_name BTConditionHasPlayer
## Check if enemy has a valid player target

func _tick(_delta: float) -> Status:
	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	return SUCCESS
