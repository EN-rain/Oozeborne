extends BTCondition
## Check if player is within attack range

@export var attack_distance_var: StringName = &"attack_distance"

func _tick(_delta: float) -> Status:
	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var attack_distance: float = blackboard.get_var(attack_distance_var, 150.0)
	var distance: float = agent.global_position.distance_to(player.global_position)
	
	if distance <= attack_distance:
		return SUCCESS
	return FAILURE
