extends Node2D

var weapon_damage = 10
var hit_enemies = []  # Track enemies already hit this swing

func _ready() -> void:
	print("[Slash] _ready called, global_position: ", global_position)
	var anim_player = $SlashEffect/SlashAnim
	if anim_player:
		print("[Slash] Playing slash_anim")
		anim_player.play("slash_anim")
	else:
		push_error("[Slash] AnimationPlayer not found!")
	
	$HitBox.body_entered.connect(_on_hitbox_body_entered)
	$HitBox.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_body_entered(body):
	# Prevent hitting the same enemy multiple times in one swing
	if body in hit_enemies:
		return
	
	# Check if it's an enemy with health
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(weapon_damage)
		hit_enemies.append(body)
	
	# Check if it's a projectile (arrow) that can be destroyed
	if body.is_in_group("projectile") and body.has_method("take_damage"):
		body.take_damage(weapon_damage)
		hit_enemies.append(body)

func _on_hitbox_area_entered(area):
	# Prevent hitting the same projectile multiple times
	if area in hit_enemies:
		return
	
	# Check if it's a projectile (arrow) that can be destroyed
	if area.is_in_group("projectile") and area.has_method("take_damage"):
		area.take_damage(weapon_damage)
		hit_enemies.append(area)

func _on_slash_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slash_anim":
		queue_free()
