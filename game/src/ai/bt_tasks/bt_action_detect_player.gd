extends BTAction
## Detect player in detection area and set as target

func _tick(_delta: float) -> Status:
	var detection_area = agent.get_node_or_null("DetectionArea")
	if detection_area == null:
		return FAILURE
	
	# Check for overlapping bodies in player group
	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			agent.player = body
			return SUCCESS
	
	# No player found
	agent.player = null
	return FAILURE
