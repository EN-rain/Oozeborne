extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/PlayerStats/VBoxContainer/HealtBar
@onready var xp_bar: ProgressBar = $Control/PlayerStats/VBoxContainer/ManaBar
@onready var level_label: Label = $Control/PlayerStats/LevelLabel
@onready var player_name_label: Label = $Control/PlayerStats/PlayerName
@onready var coin_label: Label = $Control/PlayerStats/CoinDisplay/CoinLabel
@onready var score_label: Label = $Control/Score
@onready var minimap: Control = $Control/Map
@onready var death_screen: Control = $Death
@onready var final_score_label: Label = $Death/DeathCard/VBoxContainer/FinalScore
@onready var restart_button: Button = $Death/DeathCard/VBoxContainer/Restart
@onready var menu_button: Button = $Death/DeathCard/VBoxContainer/MenuButton
@onready var store_button: Button = $Control/Store

var shop_ui: Control = null

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
	
	# Connect to coin changes
	CoinManager.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(CoinManager.get_coins())
	
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		restart_button.pressed.connect(_on_restart_pressed)
	
	if menu_button and not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		menu_button.pressed.connect(_on_menu_pressed)
	
	# Connect store button
	if store_button and not store_button.pressed.is_connected(_on_store_pressed):
		store_button.pressed.connect(_on_store_pressed)
	
	# Create shop UI
	_setup_shop_ui()

func _process(_delta):
	minimap.queue_redraw()

func set_player(player):
	player_ref = player
	var health = player.health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_player_died)
	_on_health_changed(health.current_health, health.max_health)
	
	# Set player name in UI
	if player_name_label:
		player_name_label.text = MultiplayerManager.player_ign
	
	# Connect to LevelSystem singleton for XP/level updates
	LevelSystem.xp_gained.connect(_on_xp_gained)
	LevelSystem.level_up.connect(_on_level_up)
	LevelSystem.stats_updated.connect(_on_stats_updated)
	# Initialize display
	_update_level_display(LevelSystem.get_level(player), LevelSystem.get_xp_progress(player))

func _on_health_changed(current, max):
	health_bar.max_value = max
	health_bar.value = current

func _on_player_died():
	show_death_screen()

func _on_xp_gained(entity_id: int, _amount: int, _total: int):
	if player_ref and player_ref.get_instance_id() == entity_id:
		_update_level_display(LevelSystem.get_level(player_ref), LevelSystem.get_xp_progress(player_ref))

func _on_level_up(entity_id: int, new_level: int, _stats: Dictionary):
	if player_ref and player_ref.get_instance_id() == entity_id:
		print("[UI] Player leveled up to %d!" % new_level)
		_update_level_display(new_level, LevelSystem.get_xp_progress(player_ref))

func _on_stats_updated(stats: Dictionary):
	# Stats are applied by LevelSystem directly to player
	pass

func _update_level_display(level: int, xp_progress: float):
	if level_label:
		level_label.text = "Lv.%d" % level
	if xp_bar:
		xp_bar.value = xp_progress * 100.0

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

func _on_coins_changed(total: int) -> void:
	if coin_label:
		coin_label.text = str(total)

func _setup_shop_ui():
	var shop_scene = preload("res://scenes/ui/shop.tscn")
	shop_ui = shop_scene.instantiate()
	shop_ui.hide()
	add_child(shop_ui)

func _on_store_pressed():
	if shop_ui:
		shop_ui.open()

func toggle_shop():
	if shop_ui:
		if shop_ui.visible:
			shop_ui.hide()
		else:
			shop_ui.open()
