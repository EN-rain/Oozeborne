extends BTCondition
## Check if enemy has line of sight to player

func _tick(_delta: float) -> Status:
	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var sight_ray = agent.get_node_or_null("SightRay")
	if sight_ray == null:
		return FAILURE
	
	sight_ray.target_position = player.global_position - agent.global_position
	sight_ray.force_raycast_update()
	
	if sight_ray.is_colliding():
		var collider = sight_ray.get_collider()
		if is_instance_valid(collider) and collider.is_in_group("player"):
			return SUCCESS
		return FAILURE
	
	return SUCCESS
