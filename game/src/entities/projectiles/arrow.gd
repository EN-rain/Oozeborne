extends Area2D

@export var damage: int = 15
@export var speed: float = 150.0
@export var max_distance: float = 1000.0
@export var homing_strength: float = 0.15  # How aggressively arrow tracks (0-1)
@export var homing_delay: float = 0.1  # Delay before homing kicks in
@export var homing_duration: float = 1.0  # Homing turns off after this timer

var direction: Vector2 = Vector2.RIGHT
var has_hit := false
var distance_traveled: float = 0.0
var start_position: Vector2
var player: Node2D = null
var homing_timer: float = 0.0

func _ready():
	# Arrow detects player on layer 1
	collision_mask = 1
	
	body_entered.connect(_on_body_entered)
	
	# Store starting position
	start_position = global_position
	
	# Find player in scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Rotate arrow to face direction
	rotation = direction.angle()

func _physics_process(delta):
	if has_hit:
		return
	
	# Homing timer
	homing_timer += delta
	
	# Apply homing if active (within duration window)
	if player and is_instance_valid(player) and homing_timer >= homing_delay and homing_timer < homing_delay + homing_duration:
		var to_player = (player.global_position - global_position).normalized()
		direction = direction.lerp(to_player, homing_strength).normalized()
		rotation = direction.angle()
	
	# Move arrow
	var movement = direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()
	
	# Despawn if traveled too far
	if distance_traveled >= max_distance:
		queue_free()

func _on_body_entered(body):
	if has_hit:
		return
	
	if body.is_in_group("player") and body.has_method("apply_damage"):
		has_hit = true
		body.apply_damage(damage, global_position, 150.0)
		queue_free()
	else:
		# Hit a wall or TileMapLayer — destroy arrow
		# (TileMapLayer doesn't expose collision_layer, so we skip the layer check)
		has_hit = true
		queue_free()

func take_damage(_amount: int, _source_pos: Vector2 = Vector2.ZERO, _knockback: float = 0.0):
	# Arrows have 1 HP, any damage destroys them
	queue_free()
