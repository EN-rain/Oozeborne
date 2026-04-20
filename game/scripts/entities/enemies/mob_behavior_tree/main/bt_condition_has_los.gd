extends BTCondition
class_name BTConditionHasLOS
## Check if enemy has line of sight to player

func _tick(_delta: float) -> Status:
	if agent != null and agent.has_method("has_target_line_of_sight"):
		return SUCCESS if agent.has_target_line_of_sight() else FAILURE

	var player = agent.get("player")
	if player == null or not is_instance_valid(player):
		return FAILURE
	
	var sight_ray = agent.get_node_or_null("SightRay")
	if sight_ray == null:
		return FAILURE

	# Ensure we can hit world + player in case the RayCast2D mask wasn't set in the scene.
	if "collision_mask" in sight_ray:
		sight_ray.collision_mask = 1 | 2
	sight_ray.target_position = sight_ray.to_local(player.global_position)
	sight_ray.force_raycast_update()
	
	if sight_ray.is_colliding():
		var collider = sight_ray.get_collider()
		if agent.has_method("is_targetable_player") and agent.is_targetable_player(collider):
			return SUCCESS
		return FAILURE
	
	return SUCCESS
