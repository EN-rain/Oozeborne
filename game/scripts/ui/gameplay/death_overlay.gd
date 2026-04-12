extends Control

@onready var color_rect: ColorRect = %ColorRect
@onready var death_card: PanelContainer = %DeathCard
@onready var death_card_animation_player: AnimationPlayer = %AnimationPlayer
@onready var death_title_label: Label = %YouDiedLabel
@onready var death_message_label: Label = %KillerLabel
@onready var death_card_content: VBoxContainer = %VBoxContainer
@onready var final_score_label: Label = %FinalScore
@onready var restart_button: Button = %Restart
@onready var menu_button: Button = %MenuButton
@onready var spectate_button: Button = %Spectate
var _revive_button: Button = null

var _spectating: bool = false
var _spectate_index: int = 0
var _spectate_targets: Array = []  # Array of remote player nodes
var _camera: Camera2D = null
var _original_camera_parent: Node = null

@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"
@export_file("*.json") var death_messages_json_path: String = "res://resources/data/death_messages.json"
@export var death_title_text: String = "Run Over"
@export var final_score_format: String = "Final Score: %d"
@export var match_results_format: String = "Rounds: %d | Kills: %d"
@export var fallback_killer_name: String = "something rude"
@export var death_message_format: String = "You were killed by %s. %s"
@export var overlay_hidden_color: Color = Color(0, 0, 0, 0)
@export var overlay_visible_color: Color = Color(0, 0, 0, 0.6)
@export var card_hidden_modulate: Color = Color(1, 1, 1, 0)
@export var card_visible_modulate: Color = Color(1, 1, 1, 1)
@export var content_hidden_modulate: Color = Color(1, 1, 1, 0)
@export var content_visible_modulate: Color = Color(1, 1, 1, 1)

var _funny_suffixes: Array[String] = [
	"That was not your best shift.",
	"The respawn desk has questions.",
	"An extremely avoidable tragedy.",
	"That creature now has confidence.",
	"The guild will pretend this never happened."
]


func _ready() -> void:
	visible = false
	_load_death_messages()
	if spectate_button:
		spectate_button.pressed.connect(_on_spectate_pressed)
		spectate_button.visible = false


func show_death_screen(final_score: int, killer_name: String, rounds_survived: int = 1, kills: int = 0) -> void:
	if death_title_label:
		death_title_label.text = death_title_text
	if death_message_label:
		death_message_label.text = _build_death_message(killer_name)
	if final_score_label:
		final_score_label.text = final_score_format % final_score
	
	# Show match results
	var results_label: Label = get_node_or_null("DeathCard/VBoxContainer/MatchResults")
	if results_label == null:
		results_label = Label.new()
		results_label.name = "MatchResults"
		results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		results_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.85, 0.85))
		results_label.add_theme_font_size_override("font_size", 14)
		var vbox = get_node_or_null("DeathCard/VBoxContainer")
		if vbox:
			var spacer_idx = vbox.get_child_count() - 2  # Before Restart button
			vbox.add_child(results_label)
			vbox.move_child(results_label, spacer_idx)
	results_label.text = match_results_format % [rounds_survived, kills]

	# Show spectate button only if there are remote players to watch
	_refresh_spectate_targets()
	if spectate_button:
		spectate_button.visible = _spectate_targets.size() > 0

	# Add revive button if player has revive stones
	_add_revive_button()

	visible = true
	_play_slide_in_animation()


func _play_slide_in_animation() -> void:
	# Reset to initial state for animation (card below screen)
	if color_rect:
		color_rect.color = overlay_hidden_color
	if death_card:
		death_card.modulate = card_hidden_modulate
		death_card.anchor_top = 1.2
		death_card.anchor_bottom = 1.2
	if death_card_content:
		death_card_content.modulate = content_hidden_modulate

	# Use Tween for animation (works with pause mode)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate ColorRect fade to black
	if color_rect:
		tween.tween_property(color_rect, "color", overlay_visible_color, 0.3)
	
	# Animate DeathCard sliding up and fading in
	if death_card:
		tween.parallel().tween_property(death_card, "anchor_top", 0.5, 0.5)
		tween.parallel().tween_property(death_card, "anchor_bottom", 0.5, 0.5)
		tween.parallel().tween_property(death_card, "modulate", card_visible_modulate, 0.5)
	
	# Also animate content to visible
	if death_card_content:
		tween.parallel().tween_property(death_card_content, "modulate", content_visible_modulate, 0.5)


func _build_death_message(killer_name: String) -> String:
	var resolved_killer := killer_name.strip_edges()
	if resolved_killer.is_empty():
		resolved_killer = fallback_killer_name
	return death_message_format % [resolved_killer, _funny_suffixes[randi() % _funny_suffixes.size()]]


func _load_death_messages() -> void:
	if death_messages_json_path.is_empty():
		return

	if not FileAccess.file_exists(death_messages_json_path):
		push_warning("[DeathOverlay] Missing death messages JSON: %s" % death_messages_json_path)
		return

	var file := FileAccess.open(death_messages_json_path, FileAccess.READ)
	if file == null:
		push_warning("[DeathOverlay] Failed to open death messages JSON: %s" % death_messages_json_path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("[DeathOverlay] Invalid death messages JSON format: %s" % death_messages_json_path)
		return

	var funny_suffixes: Variant = parsed.get("funny_suffixes", [])
	if not (funny_suffixes is Array) or funny_suffixes.is_empty():
		push_warning("[DeathOverlay] Missing funny_suffixes in death messages JSON: %s" % death_messages_json_path)
		return

	var loaded_suffixes: Array[String] = []
	for suffix in funny_suffixes:
		var text := str(suffix).strip_edges()
		if not text.is_empty():
			loaded_suffixes.append(text)

	if loaded_suffixes.is_empty():
		push_warning("[DeathOverlay] No valid death message suffixes found in: %s" % death_messages_json_path)
		return

	_funny_suffixes = loaded_suffixes


func _add_revive_button() -> void:
	# Remove existing revive button if any
	if _revive_button != null and is_instance_valid(_revive_button):
		_revive_button.queue_free()
		_revive_button = null

	if not ShopManager.has_revive_stone():
		return

	var vbox = get_node_or_null("DeathCard/VBoxContainer")
	if vbox == null:
		return

	_revive_button = Button.new()
	_revive_button.name = "ReviveButton"
	_revive_button.text = "Revive (Stone: %d)" % ShopManager.get_inventory_quantity("revive_stone")
	_revive_button.add_theme_font_size_override("font_size", 16)
	_revive_button.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	_revive_button.custom_minimum_size = Vector2(200, 40)
	_revive_button.pressed.connect(_on_revive_pressed)
	# Insert before restart button
	var restart_idx := -1
	for i in range(vbox.get_child_count()):
		var child := vbox.get_child(i)
		if child is Button and child.name == "Restart":
			restart_idx = i
			break
	if restart_idx >= 0:
		vbox.add_child(_revive_button)
		vbox.move_child(_revive_button, restart_idx)
	else:
		vbox.add_child(_revive_button)


func _on_revive_pressed() -> void:
	if not ShopManager.has_revive_stone():
		return
	ShopManager.use_revive_stone()
	# Find the local player and revive them
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("revive_player"):
		player.revive_player()
	_hide_death_screen()


func _hide_death_screen() -> void:
	_stop_spectating()
	visible = false
	if color_rect:
		color_rect.color = overlay_hidden_color
	if death_card:
		death_card.modulate = card_hidden_modulate
		death_card.anchor_top = 1.2
		death_card.anchor_bottom = 1.2
	get_tree().paused = false


func _on_restart_pressed() -> void:
	_stop_spectating()
	await _restart_current_run()


func _on_spectate_pressed() -> void:
	if _spectate_targets.is_empty():
		return
	_start_spectating()


func _start_spectating() -> void:
	_spectating = true
	_spectate_index = 0
	# Find and reparent camera to first remote player
	var player := get_tree().get_first_node_in_group("player")
	if player:
		_camera = player.get_node_or_null("Camera2D")
	if _camera:
		_original_camera_parent = _camera.get_parent()
		_attach_camera_to_target(_spectate_targets[0])
	# Hide death card, show spectate UI
	if death_card:
		death_card.visible = false
	if color_rect:
		color_rect.color = Color(0, 0, 0, 0.2)


func _stop_spectating() -> void:
	if not _spectating:
		return
	_spectating = false
	# Reparent camera back to original parent
	if _camera and is_instance_valid(_camera) and _original_camera_parent and is_instance_valid(_original_camera_parent):
		_camera.get_parent().remove_child(_camera)
		_original_camera_parent.add_child(_camera)
		_camera.position = Vector2.ZERO
		_camera.make_current()
	_camera = null
	_original_camera_parent = null


func _attach_camera_to_target(target: Node2D) -> void:
	if not _camera or not is_instance_valid(_camera) or not is_instance_valid(target):
		return
	_camera.get_parent().remove_child(_camera)
	target.add_child(_camera)
	_camera.position = Vector2.ZERO
	_camera.make_current()


func _refresh_spectate_targets() -> void:
	_spectate_targets.clear()
	var remote_players = MultiplayerUtils.get_remote_players()
	for user_id in remote_players:
		var data = remote_players[user_id]
		var node = data.get("node")
		if is_instance_valid(node) and node is Node2D:
			_spectate_targets.append(node)


func _input(event: InputEvent) -> void:
	if not _spectating:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_RIGHT:
			_cycle_spectate_target(1)
		elif event.keycode == KEY_LEFT:
			_cycle_spectate_target(-1)
		elif event.keycode == KEY_ESCAPE:
			_stop_spectating()
			visible = true
			if death_card:
				death_card.visible = true
			if color_rect:
				color_rect.color = overlay_visible_color
			get_viewport().set_input_as_handled()


func _cycle_spectate_target(direction: int) -> void:
	_refresh_spectate_targets()
	if _spectate_targets.is_empty():
		_stop_spectating()
		return
	_spectate_index = (_spectate_index + direction) % _spectate_targets.size()
	if _spectate_index < 0:
		_spectate_index = _spectate_targets.size() - 1
	_attach_camera_to_target(_spectate_targets[_spectate_index])
	# Show brief name of spectated player
	var target = _spectate_targets[_spectate_index]
	if target and target.has_method("get_ign"):
		# Brief overlay showing who we're watching
		pass


func _on_menu_pressed() -> void:
	get_tree().paused = false
	await MultiplayerManager.disconnect_server()
	if not main_menu_scene_path.is_empty():
		get_tree().change_scene_to_file(main_menu_scene_path)


func _restart_current_run() -> void:
	var tree := get_tree()
	if tree == null:
		return

	restart_button.disabled = true
	menu_button.disabled = true
	tree.paused = false

	var current_scene := tree.current_scene
	var scene_path := current_scene.scene_file_path if current_scene != null else ""
	if scene_path.is_empty():
		push_error("[DeathOverlay] Cannot restart run without a valid current scene path.")
		restart_button.disabled = false
		menu_button.disabled = false
		return

	var preserved_class: PlayerClass = MultiplayerManager.player_class
	await MultiplayerManager.disconnect_server()
	MultiplayerManager.player_class = preserved_class
	MultiplayerManager.player_subclass = null
	MultiplayerManager.subclass_choice_made = false
	MultiplayerManager.player_level = 1
	CoinManager.reset_coins()
	LevelSystem.reset_run_state()

	await tree.process_frame
	tree.call_deferred("change_scene_to_file", scene_path)
