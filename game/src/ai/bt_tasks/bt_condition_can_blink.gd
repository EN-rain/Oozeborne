extends BTCondition
## Check if lancer can blink (cooldown ready)

func _tick(_delta: float) -> Status:
	var can_blink = agent.get("can_blink")
	if can_blink:
		return SUCCESS
	return FAILURE
