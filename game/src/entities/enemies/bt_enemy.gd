extends CharacterBody2D
class_name BTEnemy

## Shared enemy base for LimboAI-driven mobs.

signal died(xp_reward: int)

@export var behavior_tree: BehaviorTree
@export var attacker_display_name: String = "Enemy"

@export var speed: float = 60.0
@export var stop_distance: float = 10.0
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var knockback_force: float = 300.0
@export var knockback_decay: float = 500.0
@export var max_health: int = 50
@export var xp_value: int = 10

@export var attack_distance: float = 150.0
@export var attack_cooldown: float = 2.0
@export var arrow_scene: PackedScene
@export var arrow_speed: float = 200.0
@export var prediction_lookback: int = 3
@export var max_prediction_distance: float = 300.0

@export var teleport_distance: float = 10.0
@export var blink_cooldown: float = 3.0
@export_range(0.0, 1.0, 0.01) var melee_hit_timing: float = 1.0
@export var player_group_name: StringName = &"player"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var sight_ray: RayCast2D = $SightRay
@onready var damage_timer: Timer = $DamageTimer
@onready var attack_cooldown_timer: Timer = get_node_or_null("AttackCooldownTimer") as Timer
@onready var blink_cooldown_timer: Timer = get_node_or_null("BlinkCooldownTimer") as Timer
@onready var teleport_particles: GPUParticles2D = get_node_or_null("TeleportParticles") as GPUParticles2D
@onready var bt_player: BTPlayer = get_node_or_null("BTPlayer") as BTPlayer
@onready var attack_animation_timer: Timer = Timer.new()

var player: CharacterBody2D = null
var can_damage := true
var can_attack := true
var can_blink := true
var knockback_velocity := Vector2.ZERO
var is_taking_damage := false
var is_dying := false
var is_attacking := false
var is_teleporting := false
var health: HealthComponent
var player_velocity_samples: Array[Vector2] = []
var last_player_position: Vector2 = Vector2.ZERO
var _pending_attack_mode: StringName = &""
var _pending_attack_target: Node = null
var _pending_attack_damage: int = 0
var _pending_attack_knockback: float = 0.0
var _pending_arrow_direction: Vector2 = Vector2.ZERO
var _pending_arrow_speed: float = 0.0
var _pending_attack_resolved := false


func _ready() -> void:
	health = HealthComponent.new()
	health.max_health = max_health
	add_child(health)
	health.initialize($AnimatedSprite2D/HealthBar)
	health.died.connect(_on_health_died)

	damage_timer.wait_time = damage_cooldown
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)

	if attack_cooldown_timer != null:
		attack_cooldown_timer.wait_time = attack_cooldown
		attack_cooldown_timer.one_shot = true
		attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)

	if blink_cooldown_timer != null:
		blink_cooldown_timer.wait_time = blink_cooldown
		blink_cooldown_timer.one_shot = true
		blink_cooldown_timer.timeout.connect(_on_blink_cooldown_timeout)

	if sight_ray != null:
		sight_ray.enabled = true
		sight_ray.collide_with_bodies = true
		sight_ray.collide_with_areas = false

	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_animation_timer.one_shot = true
	attack_animation_timer.timeout.connect(_on_attack_animation_timeout)
	add_child(attack_animation_timer)

	if bt_player == null and behavior_tree != null:
		bt_player = BTPlayer.new()
		bt_player.name = "BTPlayer"
		bt_player.behavior_tree = behavior_tree
		add_child(bt_player)
		bt_player.owner = self
	if bt_player != null:
		if "behavior_tree" in bt_player and bt_player.behavior_tree == null and behavior_tree != null:
			bt_player.behavior_tree = behavior_tree
		if "scene_root_hint" in bt_player:
			bt_player.scene_root_hint = self
		if "agent" in bt_player:
			bt_player.agent = self
		_sync_blackboard()


func _physics_process(delta: float) -> void:
	if player != null and is_instance_valid(player):
		var current_velocity: Vector2 = player.global_position - last_player_position
		last_player_position = player.global_position
		player_velocity_samples.append(current_velocity)
		if player_velocity_samples.size() > prediction_lookback:
			player_velocity_samples.pop_front()

	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	if not is_dying:
		move_and_slide()
	_update_locomotion_animation()


func take_damage(amount: int) -> void:
	if is_dying:
		return

	var was_killed := health.take_damage(amount)

	var damage_numbers := get_node_or_null("/root/DamageNumbers")
	if damage_numbers:
		damage_numbers.spawn_damage(global_position + Vector2(0, -20), amount, false, false)

	if not was_killed:
		_cancel_pending_attack()
		is_taking_damage = true
		velocity = Vector2.ZERO
		animated_sprite.stop()
		animated_sprite.frame = 0
		animated_sprite.play("took_damage")


func die() -> void:
	if is_dying:
		return

	is_dying = true
	_cancel_pending_attack()
	is_taking_damage = false
	is_attacking = false
	is_teleporting = false
	velocity = Vector2.ZERO

	set_physics_process(false)
	detection_area.monitoring = false
	attack_area.monitoring = false

	if bt_player != null:
		bt_player.active = false

	CoinManager.try_spawn_coin_drop(global_position, xp_value)
	died.emit(xp_value)
	if animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
	else:
		queue_free()


func is_targetable_player(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if not body.is_in_group(player_group_name):
		return false
	if body.has_method("is_targetable"):
		return body.is_targetable()
	return true


func has_target_line_of_sight() -> bool:
	if player == null or not is_instance_valid(player) or sight_ray == null:
		return false

	sight_ray.target_position = player.global_position - global_position
	sight_ray.force_raycast_update()

	if sight_ray.is_colliding():
		return is_targetable_player(sight_ray.get_collider())

	return true


func _sync_blackboard() -> void:
	if bt_player == null:
		return
	bt_player.blackboard.set_var("speed", speed)
	bt_player.blackboard.set_var("stop_distance", stop_distance)
	bt_player.blackboard.set_var("contact_damage", contact_damage)
	bt_player.blackboard.set_var("knockback_force", knockback_force)
	bt_player.blackboard.set_var("attack_distance", attack_distance)
	bt_player.blackboard.set_var("arrow_speed", arrow_speed)
	bt_player.blackboard.set_var("teleport_distance", teleport_distance)
	bt_player.blackboard.set_var("blink_cooldown", blink_cooldown)


func _on_animation_finished() -> void:
	if animated_sprite.animation == "took_damage":
		is_taking_damage = false
	elif animated_sprite.animation == "attack":
		if attack_animation_timer != null:
			attack_animation_timer.stop()
		if _pending_attack_mode == &"melee":
			if not _pending_attack_resolved:
				_resolve_melee_attack()
			_clear_pending_attack_state()
		elif _pending_attack_mode != &"":
			_resolve_pending_attack()
	elif animated_sprite.animation == "death":
		queue_free()


func _on_health_died() -> void:
	die()


func _on_damage_timer_timeout() -> void:
	can_damage = true


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


func _on_blink_cooldown_timeout() -> void:
	can_blink = true


func _on_detection_area_entered(body: Node) -> void:
	if is_targetable_player(body):
		player = body as CharacterBody2D
		last_player_position = player.global_position
		player_velocity_samples.clear()


func _on_detection_area_exited(body: Node) -> void:
	if body == player:
		player = null
		player_velocity_samples.clear()


func _on_attack_area_entered(_body: Node) -> void:
	pass


func begin_melee_attack(target: Node, damage: int, knockback: float) -> bool:
	if is_attacking or is_taking_damage or is_dying or is_teleporting:
		return false

	_pending_attack_mode = &"melee"
	_pending_attack_target = target
	_pending_attack_damage = damage
	_pending_attack_knockback = knockback
	_pending_attack_resolved = false
	velocity = Vector2.ZERO
	is_attacking = true

	if not _play_attack_animation():
		_resolve_pending_attack()
		return true

	var attack_duration := _get_animation_length("attack")
	if attack_duration <= 0.0 or attack_animation_timer == null:
		_resolve_pending_attack()
		return true

	attack_animation_timer.stop()
	var hit_delay := maxf(attack_duration * clampf(melee_hit_timing, 0.0, 1.0), 0.001)
	attack_animation_timer.start(hit_delay)

	return true


func begin_ranged_attack(direction: Vector2, projectile_speed: float) -> bool:
	if is_attacking or is_taking_damage or is_dying or is_teleporting or not can_attack:
		return false
	if arrow_scene == null:
		return false

	_pending_attack_mode = &"ranged"
	_pending_arrow_direction = direction.normalized()
	_pending_arrow_speed = projectile_speed
	_pending_attack_resolved = false
	velocity = Vector2.ZERO
	is_attacking = true
	can_attack = false
	_face_direction(_pending_arrow_direction)

	if not _play_attack_animation():
		_resolve_pending_attack()
		return true

	var attack_duration := _get_animation_length("attack")
	if attack_duration > 0.0 and attack_animation_timer != null:
		attack_animation_timer.stop()
		attack_animation_timer.start(attack_duration + 0.02)

	return true


func _play_attack_animation() -> bool:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return false
	if not animated_sprite.sprite_frames.has_animation("attack"):
		return false

	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.play("attack")
	return true


func _get_animation_length(animation_name: StringName) -> float:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0

	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	var anim_speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or anim_speed <= 0.0:
		return 0.0
	return float(frame_count) / anim_speed


func _cancel_pending_attack() -> void:
	if attack_animation_timer != null:
		attack_animation_timer.stop()
	_pending_attack_mode = &""
	_pending_attack_target = null
	_pending_attack_damage = 0
	_pending_attack_knockback = 0.0
	_pending_arrow_direction = Vector2.ZERO
	_pending_arrow_speed = 0.0
	_pending_attack_resolved = false
	is_attacking = false


func _on_attack_animation_timeout() -> void:
	if not is_attacking or _pending_attack_mode == &"":
		return
	if _pending_attack_mode == &"melee":
		if not _pending_attack_resolved:
			_resolve_melee_attack()
		return
	if _pending_attack_mode != &"":
		_resolve_pending_attack()


func _resolve_pending_attack() -> void:
	match _pending_attack_mode:
		&"melee":
			_resolve_melee_attack()
		&"ranged":
			_resolve_ranged_attack()

	_pending_attack_mode = &""
	_pending_attack_target = null
	_pending_attack_damage = 0
	_pending_attack_knockback = 0.0
	_pending_arrow_direction = Vector2.ZERO
	_pending_arrow_speed = 0.0
	_pending_attack_resolved = false
	is_attacking = false


func _resolve_melee_attack() -> void:
	_pending_attack_resolved = true
	var target := _pending_attack_target
	if target != null and is_instance_valid(target) and is_targetable_player(target) and target.has_method("apply_damage"):
		if attack_area != null and not attack_area.overlaps_body(target):
			return
		target.apply_damage(_pending_attack_damage, global_position, _pending_attack_knockback, attacker_display_name)
		can_damage = false
		if damage_timer != null:
			damage_timer.start()


func _clear_pending_attack_state() -> void:
	_pending_attack_mode = &""
	_pending_attack_target = null
	_pending_attack_damage = 0
	_pending_attack_knockback = 0.0
	_pending_arrow_direction = Vector2.ZERO
	_pending_arrow_speed = 0.0
	_pending_attack_resolved = false
	is_attacking = false


func _resolve_ranged_attack() -> void:
	if arrow_scene == null:
		can_attack = true
		return

	var arrow = arrow_scene.instantiate()
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_parent()
	if host == null or arrow == null:
		can_attack = true
		return

	host.add_child(arrow)
	arrow.global_position = global_position
	arrow.direction = _pending_arrow_direction
	arrow.speed = _pending_arrow_speed
	arrow.rotation = _pending_arrow_direction.angle()

	if attack_cooldown_timer != null:
		attack_cooldown_timer.start()


func _face_direction(direction: Vector2) -> void:
	if animated_sprite == null or direction == Vector2.ZERO:
		return
	animated_sprite.flip_h = direction.x < 0.0


func _update_locomotion_animation() -> void:
	if animated_sprite == null:
		return
	if is_dying or is_taking_damage or is_attacking or is_teleporting:
		return
	if animated_sprite.sprite_frames == null:
		return

	var horizontal_motion := velocity.x
	if absf(horizontal_motion) > 0.01:
		animated_sprite.flip_h = horizontal_motion < 0.0

	if velocity.length() > 1.0:
		if animated_sprite.sprite_frames.has_animation("walk") and animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.sprite_frames.has_animation("idle") and animated_sprite.animation != "idle":
			animated_sprite.play("idle")
