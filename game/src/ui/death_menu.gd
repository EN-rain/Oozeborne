extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealtBar
@onready var score_label: Label = $Control/Score
@onready var minimap: Control = $Control/Map
@onready var death_screen: Control = $Death
@onready var final_score_label: Label = $Death/VBoxContainer/FinalScore
@onready var restart_button: Button = $Death/VBoxContainer/Restart
@onready var menu_button: Button = $Death/VBoxContainer/MenuButton

var current_score: int = 0
var player_ref: CharacterBody2D
var slimes: Array = []
var minimap_size: Vector2
var remote_players: Dictionary = {}  # user_id -> { "pos": Vector2, "ign": String }

const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"

@export var world_size: Vector2 = Vector2(800, 600)
@export var player_color: Color = Color.GREEN
@export var remote_player_color: Color = Color.GREEN  # Same as local player
@export var slime_color: Color = Color.RED
@export var lancer_color: Color = Color.PURPLE
@export var archer_color: Color = Color.ORANGE
@export var player_size: float = 8.0
@export var remote_player_size: float = 6.0  # Slightly smaller to distinguish
@export var slime_size: float = 4.0
@export var elite_size: float = 5.0

func _ready():
	minimap_size = minimap.size
	
	minimap.draw.connect(_draw_minimap)

	death_screen.visible = false
	
	death_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		restart_button.pressed.connect(_on_restart_pressed)
	
	if menu_button and not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		menu_button.pressed.connect(_on_menu_pressed)

func _process(_delta):
	minimap.queue_redraw()

func set_player(player):
	player_ref = player
	var health = player.health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_player_died)
	_on_health_changed(health.current_health, health.max_health)

func _on_health_changed(current, max):
	health_bar.max_value = max
	health_bar.value = current

func _on_player_died():
	show_death_screen()

func show_death_screen():
	death_screen.visible = true
	
	if final_score_label:
		final_score_label.text = "Final Score: " + str(current_score)
	
	get_tree().paused = true

func add_score(amount: int):
	current_score += amount
	update_score_display()

func update_score_display():
	score_label.text = "Score: " + str(current_score)

func register_slime(slime):
	if slime not in slimes:
		slimes.append(slime)
		slime.tree_exiting.connect(_on_slime_removed.bind(slime))

func _on_slime_removed(slime):
	slimes.erase(slime)

## Register a remote player for minimap display
func register_remote_player(user_id: String, ign: String) -> void:
	remote_players[user_id] = { "pos": Vector2.ZERO, "ign": ign }

func update_remote_player_ign(user_id: String, ign: String) -> void:
	if remote_players.has(user_id):
		remote_players[user_id]["ign"] = ign

## Update remote player position on minimap
func update_remote_player_pos(user_id: String, pos: Vector2) -> void:
	if remote_players.has(user_id):
		remote_players[user_id]["pos"] = pos

## Remove remote player from minimap
func unregister_remote_player(user_id: String) -> void:
	remote_players.erase(user_id)

func _draw_minimap():
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	minimap.draw_rect(Rect2(Vector2.ZERO, minimap_size), Color(0, 0, 0, 0.5))
	
	minimap.draw_rect(Rect2(Vector2.ZERO, minimap_size), Color.WHITE, false, 2.0)
	
	var player_minimap_pos = minimap_size / 2
	minimap.draw_circle(player_minimap_pos, player_size, player_color)
	
	var zoom = minimap_size.x / world_size.x
	
	for enemy in slimes:
		if is_instance_valid(enemy):
			var enemy_minimap_pos = world_to_minimap(enemy.global_position, player_minimap_pos, zoom)
			
			enemy_minimap_pos = clamp_to_minimap(enemy_minimap_pos)
			
			var enemy_color = slime_color
			var enemy_size = slime_size
			
			if enemy.get_script():
				var script_path = enemy.get_script().resource_path
				
				if "lancer" in script_path.to_lower():
					enemy_color = lancer_color
					enemy_size = elite_size
				elif "archer" in script_path.to_lower():
					enemy_color = archer_color
					enemy_size = elite_size
			
			minimap.draw_circle(enemy_minimap_pos, enemy_size, enemy_color)
	
	# Draw remote players as green dots
	for user_id in remote_players:
		var rp_data = remote_players[user_id]
		var rp_pos = rp_data["pos"]
		var rp_minimap_pos = world_to_minimap(rp_pos, player_minimap_pos, zoom)
		rp_minimap_pos = clamp_to_minimap(rp_minimap_pos)
		minimap.draw_circle(rp_minimap_pos, remote_player_size, remote_player_color)

func world_to_minimap(world_pos: Vector2, center: Vector2, zoom: float) -> Vector2:
	var relative_pos = world_pos - player_ref.global_position
	var minimap_pos = center + (relative_pos * zoom)
	return minimap_pos

func clamp_to_minimap(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, slime_size, minimap_size.x - slime_size),
		clamp(pos.y, slime_size, minimap_size.y - slime_size)
	)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	await MultiplayerManager.disconnect_server()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
