extends CharacterBody2D

enum State { IDLE, CHASE }
var current_state = State.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var sight_ray: RayCast2D = $SightRay
@onready var damage_timer: Timer = $DamageTimer
@onready var teleport_particles: GPUParticles2D = $TeleportParticles
@onready var blink_cooldown_timer: Timer = $BlinkCooldownTimer
@onready var vulnerability_particles: CPUParticles2D = $VulnerabilityParticles

@export var speed: float = 60.0
@export var stop_distance: float = 10.0
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var knockback_force: float = 300.0
@export var knockback_decay: float = 500.0
@export var teleport_delay: float = 1.0
@export var teleport_distance: float = 10.0  # Reduced from 20 to get closer for attack
@export var blink_cooldown: float = 3.0  # Reduced from 15 for testing
@export var max_health: int = 100
@export var vulnerability_duration: float = 3.0  # Duration of vulnerability after teleport

const TELEPORT_FADE_TIME := 0.3
const INITIAL_TELEPORT_OFFSET := 20.0  # Reduced from 100 to teleport closer
const ATTACK_HIT_DELAY := 0.3

var player: CharacterBody2D = null
var can_damage := true
var knockback_velocity := Vector2.ZERO
var is_taking_damage := false
var is_dying := false
var is_attacking := false
var is_teleporting := false
var has_teleported_to_player := false
var can_blink := true
var chase_frame_count := 0
var is_blinking := false
var fade_tween: Tween = null
var last_debug_state := ""
var lancer_id := 0  # Unique ID for each lancer instance
var player_in_detection_range := false
var health: HealthComponent

func _ready():
	# Assign unique ID for debugging
	lancer_id = randi() % 1000
	
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
	
	blink_cooldown_timer.wait_time = blink_cooldown
	blink_cooldown_timer.one_shot = true
	blink_cooldown_timer.timeout.connect(_on_blink_cooldown_timeout)
	
	teleport_particles.emitting = false
	vulnerability_particles.emitting = false

func _physics_process(delta):
	# Failsafe: reset stuck animation flags if animation isn't playing
	if is_taking_damage and animated_sprite.animation != "took_damage":
		is_taking_damage = false
	if is_attacking and animated_sprite.animation != "attack":
		is_attacking = false
	
	if not _is_action_locked():
		match current_state:
			State.IDLE:
				_idle_state()
			State.CHASE:
				_chase_state()
	
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	
	if not is_dying and not is_attacking and not is_teleporting:
		move_and_slide()

# ---------------- STATES ----------------
func _idle_state():
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	
	# Transition back to CHASE if we have a valid player and line of sight
	# (don't require player_in_detection_range - it may have briefly gone false after a blink)
	if is_instance_valid(player) and has_line_of_sight():
		player_in_detection_range = true
		change_state(State.CHASE)

func _chase_state():
	if not _has_valid_player():
		chase_frame_count = 0
		player = null
		change_state(State.IDLE)
		return
	
	if not has_line_of_sight():
		chase_frame_count = 0
		change_state(State.IDLE)
		return
	
	chase_frame_count += 1
	
	# Only blink after chasing for at least 5 frames AND initial teleport done (prevents mini-teleport bug)
	if can_blink and not is_teleporting and not is_blinking and has_teleported_to_player and chase_frame_count > 5:
		can_blink = false
		chase_frame_count = 0
		start_blink()
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
	current_state = new_state

# ---------------- DAMAGE ----------------
func take_damage(amount: int):
	if is_taking_damage or is_dying:
		return
	
	var died = health.take_damage(amount)
	
	if not died:
		is_taking_damage = true
		animated_sprite.play("took_damage")

func _on_animation_finished():
	if animated_sprite.animation == "took_damage":
		is_taking_damage = false
	elif animated_sprite.animation == "death":
		queue_free()
	elif animated_sprite.animation == "attack":
		is_attacking = false

func _on_health_died():
	die()

func die():
	if is_dying:
		return
	
	is_dying = true
	is_taking_damage = false
	is_attacking = false
	is_teleporting = false
	velocity = Vector2.ZERO
	
	set_physics_process(false)
	detection_area.monitoring = false
	attack_area.monitoring = false
	
	queue_free()

# ---------------- ATTACK ----------------
func _on_attack_area_entered(body):
	if body.is_in_group("player") and not is_teleporting:
		start_attack(body)

func start_attack(body: CharacterBody2D):
	if is_attacking or is_taking_damage or is_dying or is_teleporting:
		return
	
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("attack")
	
	await get_tree().create_timer(ATTACK_HIT_DELAY).timeout
	
	# Guard: lancer or player may have died during the await
	if is_dying or not is_instance_valid(body):
		is_attacking = false
		return
	
	if can_damage and body.has_method("apply_damage"):
		body.apply_damage(contact_damage, global_position, knockback_force)
		can_damage = false
		damage_timer.start()

func _on_damage_timer_timeout():
	can_damage = true

# ---------------- DETECTION ----------------
func _on_detection_area_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_detection_range = true
		
		if not has_teleported_to_player:
			has_teleported_to_player = true
			initial_teleport()

func _on_detection_area_exited(body):
	if body.is_in_group("player") and body == player:
		player_in_detection_range = false
		# Do NOT null out player here - after a blink the player may briefly
		# exit the detection area, and clearing player causes a permanent lock.
		# The chase/idle states will handle re-engagement via LOS checks.

# ---------------- TELEPORT ----------------
func initial_teleport():
	if not _has_valid_player():
		return
	
	if is_teleporting or is_blinking:
		return
	
	is_teleporting = true
	is_blinking = true  # Prevent chase state from running during initial teleport
	velocity = Vector2.ZERO
	
	teleport_particles.emitting = true
	
	await _fade_sprite_alpha(0.0, TELEPORT_FADE_TIME)
	
	# Guard after await
	if not _has_valid_player() or is_dying:
		animated_sprite.modulate.a = 1.0
		is_teleporting = false
		return
	
	var direction_to_player = (player.global_position - global_position).normalized()
	var target_pos = player.global_position - (direction_to_player * INITIAL_TELEPORT_OFFSET)
	global_position = target_pos
	
	teleport_particles.emitting = true
	
	await _fade_sprite_alpha(1.0, TELEPORT_FADE_TIME)
	
	if is_dying:
		is_teleporting = false
		is_blinking = false
		return
	
	is_teleporting = false
	is_blinking = false
	can_blink = false
	blink_cooldown_timer.start()
	
	# Attack instantly after initial teleport if player is in melee range
	if is_instance_valid(player) and attack_area.overlaps_body(player):
		start_attack(player)
	
	# Apply vulnerability debuff to self after teleport
	_apply_vulnerability()

func start_blink():
	if not _has_valid_player() or is_teleporting or is_blinking:
		return
	
	is_blinking = true
	is_teleporting = true
	can_blink = false
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	
	teleport_to_player_back()

func teleport_to_player_back():
	if not _has_valid_player():
		attack_area.monitoring = true
		is_teleporting = false
		is_blinking = false
		return
	
	teleport_particles.emitting = true
	
	await _fade_sprite_alpha(0.0, TELEPORT_FADE_TIME)
	
	# Re-validate player after await - it may have been freed during animation
	if not _has_valid_player():
		animated_sprite.modulate.a = 1.0
		attack_area.monitoring = true
		is_teleporting = false
		is_blinking = false
		blink_cooldown_timer.start()
		return
	
	var player_facing = Vector2.RIGHT
	if player.has_node("AnimatedSprite2D"):
		var player_sprite = player.get_node("AnimatedSprite2D")
		if player_sprite.flip_h:
			player_facing = Vector2.LEFT
	
	var behind_position = player.global_position - (player_facing * teleport_distance)
	global_position = behind_position
	
	teleport_particles.emitting = true
	
	await _fade_sprite_alpha(1.0, TELEPORT_FADE_TIME)
	
	# Re-validate after second await
	if not _has_valid_player():
		attack_area.monitoring = true
		is_teleporting = false
		blink_cooldown_timer.start()  # reset can_blink so lancer doesn't get stuck
		return
	
	attack_area.monitoring = true
	is_teleporting = false
	is_blinking = false
	
	# Ensure we're in CHASE state after blink so the lancer walks toward the player
	change_state(State.CHASE)
	
	# Start cooldown immediately after blink
	blink_cooldown_timer.start()
	
	# Attack instantly after blink if player is already in melee area.
	# NOTE: Attack animation happens AFTER cooldown starts, so timer runs during attack
	if is_instance_valid(player) and attack_area.overlaps_body(player):
		start_attack(player)
	
	# Apply vulnerability debuff to self after teleport
	_apply_vulnerability()

func _apply_vulnerability():
	# Apply vulnerability to self after teleporting
	set_meta("damage_modifier", 1.3)  # 30% more damage taken
	vulnerability_particles.emitting = true
	print("[Lancer] Vulnerability applied for %.1fs" % vulnerability_duration)
	
	await get_tree().create_timer(vulnerability_duration).timeout
	
	# Remove vulnerability after duration
	if has_meta("damage_modifier"):
		remove_meta("damage_modifier")
		vulnerability_particles.emitting = false
		print("[Lancer] Vulnerability removed")

func _on_blink_cooldown_timeout():
	can_blink = true

# ---------------- LINE OF SIGHT ----------------
func has_line_of_sight() -> bool:
	if not _has_valid_player():
		return false
	
	sight_ray.target_position = player.global_position - global_position
	sight_ray.force_raycast_update()
	
	if sight_ray.is_colliding():
		var collider = sight_ray.get_collider()
		return is_instance_valid(collider) and collider.is_in_group("player")
	
	return true

func _is_action_locked() -> bool:
	return is_taking_damage or is_dying or is_attacking or is_teleporting or is_blinking

func _has_valid_player() -> bool:
	return is_instance_valid(player)

func _fade_sprite_alpha(target_alpha: float, duration: float) -> void:
	# Kill any existing tween to prevent overlap
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(animated_sprite, "modulate:a", target_alpha, duration)
	await fade_tween.finished
	fade_tween = null
