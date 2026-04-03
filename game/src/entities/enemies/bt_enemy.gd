extends CharacterBody2D
class_name BTEnemy

## Base enemy class that works with LimboAI behavior trees

@export var behavior_tree: BehaviorTree

@export var speed: float = 60.0
@export var stop_distance: float = 10.0
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var knockback_force: float = 300.0
@export var knockback_decay: float = 500.0
@export var max_health: int = 50
@export var xp_value: int = 10  ## XP awarded when killed

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var sight_ray: RayCast2D = $SightRay
@onready var damage_timer: Timer = $DamageTimer

var player: CharacterBody2D = null
var can_damage := true
var knockback_velocity := Vector2.ZERO
var is_taking_damage := false
var is_dying := false
var health: HealthComponent
var bt_player: BTPlayer


signal died(xp_reward: int)  ## Emitted when enemy dies, includes XP value

func _ready() -> void:
	health = HealthComponent.new()
	health.max_health = max_health
	add_child(health)
	health.initialize($AnimatedSprite2D/HealthBar)
	health.died.connect(_on_health_died)

	damage_timer.wait_time = damage_cooldown
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)

	sight_ray.enabled = true
	sight_ray.collide_with_bodies = true
	sight_ray.collide_with_areas = false

	if behavior_tree:
		bt_player = BTPlayer.new()
		bt_player.behavior_tree = behavior_tree
		add_child(bt_player)
		bt_player.blackboard.set_var("speed", speed)
		bt_player.blackboard.set_var("stop_distance", stop_distance)
		bt_player.blackboard.set_var("contact_damage", contact_damage)
		bt_player.blackboard.set_var("knockback_force", knockback_force)

	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	attack_area.body_entered.connect(_on_attack_area_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	if not is_dying:
		move_and_slide()


func take_damage(amount: int) -> void:
	if is_taking_damage or is_dying:
		return

	var was_killed := health.take_damage(amount)
	
	# Spawn damage number
	var damage_numbers := get_node_or_null("/root/DamageNumbers")
	if damage_numbers:
		damage_numbers.spawn_damage(global_position + Vector2(0, -20), amount, false, false)
	
	if not was_killed:
		is_taking_damage = true
		animated_sprite.play("took_damage")


func die() -> void:
	if is_dying:
		return

	is_dying = true
	is_taking_damage = false
	velocity = Vector2.ZERO

	set_physics_process(false)
	detection_area.monitoring = false
	attack_area.monitoring = false

	if bt_player:
		bt_player.active = false

	# Spawn coin drop (50% chance)
	CoinManager.try_spawn_coin_drop(global_position, xp_value)

	# Emit death signal with XP reward before playing animation
	died.emit(xp_value)
	animated_sprite.play("death")


func _on_animation_finished() -> void:
	if animated_sprite.animation == "took_damage":
		is_taking_damage = false
	elif animated_sprite.animation == "death":
		queue_free()


func _on_health_died() -> void:
	die()


func _on_damage_timer_timeout() -> void:
	can_damage = true


func _on_detection_area_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body as CharacterBody2D


func _on_detection_area_exited(body: Node) -> void:
	if body.is_in_group("player") and body == player:
		player = null


func _on_attack_area_entered(_body: Node) -> void:
	pass
