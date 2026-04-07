extends CharacterBody2D

enum State { IDLE, CHASE }
var current_state = State.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var sight_ray: RayCast2D = $SightRay
@onready var damage_timer: Timer = $DamageTimer

@export var speed: float = 60.0
@export var stop_distance: float = 10.0
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var knockback_force: float = 300.0
@export var knockback_decay: float = 500.0
@export var max_health: int = 50
@export var xp_value: int = 10  ## XP awarded when killed
@export var idle_move_interval: float = 3.0
@export var idle_move_radius: float = 64.0
@export var idle_move_speed_multiplier: float = 0.45
@export var player_group_name: StringName = &"player"

signal died(xp_reward: int)  ## Emitted when enemy dies, includes XP value

var player: CharacterBody2D = null
var can_damage := true
var knockback_velocity := Vector2.ZERO
var is_taking_damage := false
var is_dying := false
var health: HealthComponent
var _idle_move_timer: float = 0.0
var _idle_target: Vector2 = Vector2.ZERO
var _has_idle_target: bool = false

func _ready():
	# Create and initialize health component
	health = HealthComponent.new()
	health.max_health = max_health
	add_child(health)
	health.initialize($AnimatedSprite2D/HealthBar)
	health.died.connect(_on_health_died)
	
	animated_sprite.animation_finished.connect(_on_animation_finished)
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	
	damage_timer.wait_time = damage_cooldown
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	
	sight_ray.enabled = true
	sight_ray.collide_with_bodies = true
	sight_ray.collide_with_areas = false
	_reset_idle_roam()

func _physics_process(delta):
	if not is_dying:
		_idle_move_timer -= delta
	if not is_taking_damage and not is_dying:
		match current_state:
			State.IDLE:
				_idle_state()
			State.CHASE:
				_chase_state()
	
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	
	if not is_dying:
		move_and_slide()

# ---------------- STATES ----------------
func _idle_state():
	if _idle_move_timer <= 0.0:
		_pick_idle_target()
	
	if _has_idle_target:
		var idle_direction := _idle_target - global_position
		if idle_direction.length() > 6.0:
			velocity = idle_direction.normalized() * speed * idle_move_speed_multiplier
			animated_sprite.play("walk")
			animated_sprite.flip_h = velocity.x < 0
		else:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
			_has_idle_target = false
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
	
	if player and has_line_of_sight():
		change_state(State.CHASE)

func _chase_state():
	if not player or not has_line_of_sight():
		change_state(State.IDLE)
		return
	
	var direction := (player.global_position - global_position).normalized()
	var distance := global_position.distance_to(player.global_position)
	
	if distance <= stop_distance:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
	else:
		animated_sprite.play("walk")
		velocity = direction * speed
		animated_sprite.flip_h = direction.x < 0

func change_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	if new_state == State.IDLE:
		_reset_idle_roam()
	elif new_state == State.CHASE:
		_has_idle_target = false

# ---------------- DAMAGE ----------------
func take_damage(amount: int):
	if is_taking_damage or is_dying:
		return
	
	var was_killed = health.take_damage(amount)
	
	if not was_killed:
		is_taking_damage = true
		animated_sprite.play("took_damage")

func _on_animation_finished():
	if animated_sprite.animation == "took_damage":
		is_taking_damage = false
	elif animated_sprite.animation == "death":
		queue_free()

func _on_health_died():
	die()

func die():
	is_dying = true
	is_taking_damage = false
	velocity = Vector2.ZERO
	
	set_physics_process(false)
	detection_area.monitoring = false
	attack_area.monitoring = false
	
	# Emit death signal with XP reward before playing animation
	died.emit(xp_value)
	animated_sprite.play("death")

# ---------------- ATTACK ----------------
func _on_attack_area_entered(body):
	if not can_damage:
		return
	
	if _is_targetable_player(body) and body.has_method("apply_damage"):
		body.apply_damage(contact_damage, global_position, knockback_force, "Blue Slime")
		can_damage = false
		damage_timer.start()

func _on_damage_timer_timeout():
	can_damage = true

# ---------------- DETECTION ----------------
func _on_detection_area_entered(body):
	if _is_targetable_player(body):
		player = body

func _on_detection_area_exited(body):
	if body == player:
		player = null
		change_state(State.IDLE)

# ---------------- LINE OF SIGHT ----------------
func has_line_of_sight() -> bool:
	if not player:
		return false
	
	sight_ray.target_position = player.global_position - global_position
	sight_ray.force_raycast_update()
	
	if sight_ray.is_colliding():
		return _is_targetable_player(sight_ray.get_collider())
	
	return true


func _is_targetable_player(body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if not body.is_in_group(player_group_name):
		return false
	if body.has_method("is_targetable"):
		return body.is_targetable()
	return true


func _reset_idle_roam() -> void:
	_idle_move_timer = randf_range(0.4, idle_move_interval)
	_has_idle_target = false


func _pick_idle_target() -> void:
	_idle_move_timer = idle_move_interval
	var random_offset := Vector2(
		randf_range(-idle_move_radius, idle_move_radius),
		randf_range(-idle_move_radius, idle_move_radius)
	)
	if random_offset.length() < 8.0:
		random_offset = Vector2.RIGHT.rotated(randf() * TAU) * 16.0
	_idle_target = global_position + random_offset
	_has_idle_target = true
