extends BTAction
class_name BTActionMeleeAttack
## Melee attack - damage player when in contact

@export var damage_var: StringName = &"contact_damage"
@export var knockback_var: StringName = &"knockback_force"

func _tick(_delta: float) -> Status:
	var attack_area = agent.get_node_or_null("AttackArea")
	if attack_area == null:
		return FAILURE
	
	var can_damage = agent.get("can_damage")
	if not can_damage:
		return FAILURE
	
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("apply_damage"):
			var damage: int = blackboard.get_var(damage_var, 10)
			var knockback: float = blackboard.get_var(knockback_var, 300.0)
			
			body.apply_damage(damage, agent.global_position, knockback)
			agent.can_damage = false
			
			var damage_timer = agent.get_node_or_null("DamageTimer")
			if damage_timer:
				damage_timer.start()
			
			return SUCCESS
	
	return FAILURE
