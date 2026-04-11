extends CanvasLayer

@onready var control_panel: HudControlPanel = $Control
@onready var player_panel: HudPlayerPanel = $Control/PlayerStats
@onready var minimap: HudMinimap = %Map
@onready var death_screen: Control = %Death
@onready var skills_root: HudSkillBar = %Skills
@onready var stats_panel: HudStatsPanel = $Stats
@onready var chat_box: Control = %ChatBox

var _disconnect_overlay: PanelContainer = null
var _disconnect_label: Label = null
var _disconnect_timer: float = 0.0
var _disconnect_reconnect_btn: Button = null

# Boss health bar
var _boss_bar_container: PanelContainer = null
var _boss_name_label: Label = null
var _boss_health_bar: ProgressBar = null
var _boss_phase_label: Label = null
var _tracked_boss: BTBoss = null

var player_ref: CharacterBody2D

@export var block_input_when_overlay_open: bool = false


func _ready() -> void:
	if control_panel != null:
		control_panel.set_block_input_when_overlay_open(block_input_when_overlay_open)
	if player_panel != null and not player_panel.player_died.is_connected(_on_player_died):
		player_panel.player_died.connect(_on_player_died)
	if chat_box != null and chat_box.has_signal("chat_message_sent"):
		if chat_box.chat_message_sent.is_connected(_on_chat_message_sent):
			chat_box.chat_message_sent.disconnect(_on_chat_message_sent)
		chat_box.chat_message_sent.connect(_on_chat_message_sent)
	# Connect connection lost signal
	if not MultiplayerManager.connection_lost.is_connected(_on_connection_lost):
		MultiplayerManager.connection_lost.connect(_on_connection_lost)
	_create_disconnect_overlay()
	_create_boss_health_bar()


func set_player(player: CharacterBody2D) -> void:
	if LevelSystem.xp_gained.is_connected(_on_xp_gained):
		LevelSystem.xp_gained.disconnect(_on_xp_gained)
	if LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.disconnect(_on_level_up)
	if LevelSystem.stats_updated.is_connected(_on_stats_updated):
		LevelSystem.stats_updated.disconnect(_on_stats_updated)

	player_ref = player
	if player_panel != null:
		player_panel.set_player(player)
	if stats_panel != null:
		stats_panel.set_player(player)
	if minimap != null:
		minimap.set_player(player)
	if skills_root != null:
		skills_root.refresh_skill_hud()

	if not LevelSystem.xp_gained.is_connected(_on_xp_gained):
		LevelSystem.xp_gained.connect(_on_xp_gained)
	if not LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.connect(_on_level_up)
	if not LevelSystem.stats_updated.is_connected(_on_stats_updated):
		LevelSystem.stats_updated.connect(_on_stats_updated)

	refresh_player_level_display()


func set_mob_spawner(_spawner: MobSpawner) -> void:
	pass


func _on_player_died(killer_name: String = "") -> void:
	if death_screen != null and death_screen.has_method("show_death_screen"):
		var score := control_panel.get_current_score() if control_panel != null else 0
		var main_node := get_tree().get_first_node_in_group("game_main")
		var rounds := 1
		var kills := 0
		if main_node and main_node.has_method("get"):
			if main_node.get("round_manager") != null:
				rounds = main_node.round_manager.current_round
			if main_node.get("kill_count") != null:
				kills = main_node.kill_count
		death_screen.show_death_screen(score, killer_name, rounds, kills)


func _on_xp_gained(entity_id: int, _amount: int, _total: int) -> void:
	var resolved_player := _resolve_player_ref()
	if resolved_player != null and resolved_player.get_instance_id() == entity_id and player_panel != null:
		player_panel.refresh_level_display(LevelSystem.get_level(resolved_player), LevelSystem.get_xp_progress(resolved_player))


func _on_level_up(entity_id: int, new_level: int, _stats: Dictionary) -> void:
	var resolved_player := _resolve_player_ref()
	if resolved_player != null and resolved_player.get_instance_id() == entity_id:
		if player_panel != null:
			player_panel.refresh_level_display(new_level, LevelSystem.get_xp_progress(resolved_player))
		refresh_player_stat_cards()


func _on_stats_updated(entity_id: int, _stats: Dictionary) -> void:
	var resolved_player := _resolve_player_ref()
	if resolved_player != null and resolved_player.get_instance_id() == entity_id:
		if player_panel != null:
			player_panel.refresh_level_display(LevelSystem.get_level(resolved_player), LevelSystem.get_xp_progress(resolved_player))
		refresh_player_stat_cards()


func refresh_player_level_display() -> void:
	var resolved_player := _resolve_player_ref()
	if resolved_player == null:
		return
	if player_panel != null:
		player_panel.refresh_level_display(LevelSystem.get_level(resolved_player), LevelSystem.get_xp_progress(resolved_player))
	refresh_player_stat_cards()


func refresh_player_stat_cards() -> void:
	if stats_panel != null:
		stats_panel.refresh_player_stat_cards()


func _resolve_player_ref() -> CharacterBody2D:
	if player_ref != null and is_instance_valid(player_ref):
		return player_ref

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	var resolved_player := current_scene.get_node_or_null("Player") as CharacterBody2D
	if resolved_player != null:
		set_player(resolved_player)
	return player_ref


func add_score(amount: int) -> void:
	if control_panel != null:
		control_panel.add_score(amount)


func get_current_score() -> int:
	return control_panel.get_current_score() if control_panel != null else 0


func set_current_score(value: int) -> void:
	if control_panel != null:
		control_panel.set_current_score(value)


func update_score_display() -> void:
	if control_panel != null:
		control_panel.update_score_display()


func update_mob_counter(current_alive: int, total_in_round: int) -> void:
	if control_panel != null:
		control_panel.update_mob_counter(current_alive, total_in_round)


func show_round_level(round_number: int, added_mobs: int, profile: Dictionary) -> void:
	if control_panel != null:
		control_panel.show_round_level(round_number, added_mobs, profile)


func register_slime(slime: Node) -> void:
	if minimap != null:
		minimap.register_slime(slime)


func register_remote_player(user_id: String, ign: String) -> void:
	if minimap != null:
		minimap.register_remote_player(user_id, ign)


func update_remote_player_ign(user_id: String, ign: String) -> void:
	if minimap != null:
		minimap.update_remote_player_ign(user_id, ign)


func update_remote_player_pos(user_id: String, pos: Vector2) -> void:
	if minimap != null:
		minimap.update_remote_player_pos(user_id, pos)


func unregister_remote_player(user_id: String) -> void:
	if minimap != null:
		minimap.unregister_remote_player(user_id)


func toggle_shop() -> void:
	if control_panel != null:
		control_panel.toggle_shop()


func toggle_skill_tree() -> void:
	if control_panel != null:
		control_panel.toggle_skill_tree()


func has_blocking_overlay_open() -> bool:
	return control_panel.has_blocking_overlay_open() if control_panel != null else false


func is_pointer_over_ui(pointer_position: Vector2) -> bool:
	return control_panel.is_pointer_over_ui(pointer_position) if control_panel != null else false


func _on_chat_message_sent(message: String) -> void:
	MultiplayerManager.send_match_state({
		"type": "chat_message",
		"sender": MultiplayerManager.player_ign,
		"message": message
	})


func add_chat_message(sender_name: String, message: String, is_admin: bool = false, is_party_leader: bool = false) -> void:
	if chat_box != null and chat_box.has_method("add_remote_message"):
		chat_box.add_remote_message(sender_name, message, is_admin, is_party_leader)


func toggle_chat() -> void:
	if chat_box == null:
		return
	chat_box.visible = not chat_box.visible
	if chat_box.visible:
		var input_field: LineEdit = chat_box.get("input_field") as LineEdit
		if input_field != null:
			input_field.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and not has_blocking_overlay_open():
			if chat_box != null and chat_box.visible:
				return  # Let chat box handle Enter
			toggle_chat()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _disconnect_overlay != null and _disconnect_overlay.visible:
		_disconnect_timer += delta
		if _disconnect_label != null:
			var dots = ".".repeat(int(_disconnect_timer * 2) % 4)
			_disconnect_label.text = "Connection Lost — Reconnecting%s" % dots
	_update_boss_health_bar()


func _create_disconnect_overlay() -> void:
	_disconnect_overlay = PanelContainer.new()
	_disconnect_overlay.name = "DisconnectOverlay"
	_disconnect_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_disconnect_overlay.offset_top = 40
	_disconnect_overlay.offset_left = -160
	_disconnect_overlay.offset_right = 160
	_disconnect_overlay.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.05, 0.05, 0.92)
	style.border_color = Color(0.9, 0.2, 0.2)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	_disconnect_overlay.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_disconnect_label = Label.new()
	_disconnect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_disconnect_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_disconnect_label.add_theme_font_size_override("font_size", 16)
	_disconnect_label.text = "Connection Lost — Reconnecting..."
	vbox.add_child(_disconnect_label)

	_disconnect_reconnect_btn = Button.new()
	_disconnect_reconnect_btn.text = "Return to Menu"
	_disconnect_reconnect_btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7))
	_disconnect_reconnect_btn.add_theme_font_size_override("font_size", 14)
	_disconnect_reconnect_btn.pressed.connect(_on_disconnect_return_menu)
	vbox.add_child(_disconnect_reconnect_btn)

	_disconnect_overlay.add_child(vbox)
	add_child(_disconnect_overlay)


func _on_connection_lost() -> void:
	if _disconnect_overlay != null:
		_disconnect_overlay.visible = true
	_disconnect_timer = 0.0
	get_tree().paused = true


func _on_disconnect_return_menu() -> void:
	get_tree().paused = false
	if _disconnect_overlay != null:
		_disconnect_overlay.visible = false
	MultiplayerManager._cleanup_socket_connection()
	MultiplayerManager._reset_match_state()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _create_boss_health_bar() -> void:
	_boss_bar_container = PanelContainer.new()
	_boss_bar_container.name = "BossHealthBarContainer"
	_boss_bar_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_bar_container.offset_top = 8
	_boss_bar_container.offset_left = -180
	_boss_bar_container.offset_right = 180
	_boss_bar_container.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.12, 0.88)
	style.border_color = Color(0.6, 0.2, 0.8)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	_boss_bar_container.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER

	_boss_name_label = Label.new()
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_boss_name_label.add_theme_color_override("font_color", Color(0.85, 0.65, 1.0))
	_boss_name_label.add_theme_font_size_override("font_size", 14)
	_boss_name_label.text = "Boss"
	_boss_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_boss_name_label)

	_boss_phase_label = Label.new()
	_boss_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_boss_phase_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	_boss_phase_label.add_theme_font_size_override("font_size", 12)
	_boss_phase_label.text = "Phase 1"
	title_row.add_child(_boss_phase_label)

	vbox.add_child(title_row)

	_boss_health_bar = ProgressBar.new()
	_boss_health_bar.min_value = 0.0
	_boss_health_bar.max_value = 100.0
	_boss_health_bar.value = 100.0
	_boss_health_bar.show_percentage = false
	_boss_health_bar.custom_minimum_size = Vector2(340, 16)

	var bar_fg := StyleBoxFlat.new()
	bar_fg.bg_color = Color(0.7, 0.15, 0.9)
	bar_fg.corner_radius_bottom_left = 3
	bar_fg.corner_radius_bottom_right = 3
	bar_fg.corner_radius_top_left = 3
	bar_fg.corner_radius_top_right = 3
	_boss_health_bar.add_theme_stylebox_override("fill", bar_fg)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.08, 0.2, 0.8)
	bar_bg.corner_radius_bottom_left = 3
	bar_bg.corner_radius_bottom_right = 3
	bar_bg.corner_radius_top_left = 3
	bar_bg.corner_radius_top_right = 3
	_boss_health_bar.add_theme_stylebox_override("background", bar_bg)

	vbox.add_child(_boss_health_bar)

	_boss_bar_container.add_child(vbox)
	add_child(_boss_bar_container)


func track_boss(boss: BTBoss) -> void:
	if _tracked_boss != null and is_instance_valid(_tracked_boss):
		if _tracked_boss.phase_changed.is_connected(_on_boss_phase_changed):
			_tracked_boss.phase_changed.disconnect(_on_boss_phase_changed)
		if _tracked_boss.boss_died.is_connected(_on_boss_died):
			_tracked_boss.boss_died.disconnect(_on_boss_died)
	_tracked_boss = boss
	if boss == null:
		if _boss_bar_container != null:
			_boss_bar_container.visible = false
		return
	if boss.phase_changed.is_connected(_on_boss_phase_changed):
		boss.phase_changed.disconnect(_on_boss_phase_changed)
	boss.phase_changed.connect(_on_boss_phase_changed)
	if boss.boss_died.is_connected(_on_boss_died):
		boss.boss_died.disconnect(_on_boss_died)
	boss.boss_died.connect(_on_boss_died)
	if _boss_name_label != null:
		_boss_name_label.text = boss.boss_display_name
	if _boss_phase_label != null:
		_boss_phase_label.text = "Phase %d" % boss.current_phase
	if _boss_bar_container != null:
		_boss_bar_container.visible = true


func _update_boss_health_bar() -> void:
	if _tracked_boss == null or not is_instance_valid(_tracked_boss):
		if _boss_bar_container != null:
			_boss_bar_container.visible = false
		_tracked_boss = null
		return
	if _boss_health_bar != null:
		_boss_health_bar.value = _tracked_boss.get_health_percent() * 100.0


func _on_boss_phase_changed(phase: int) -> void:
	if _boss_phase_label != null:
		_boss_phase_label.text = "Phase %d" % phase


func _on_boss_died() -> void:
	if _boss_bar_container != null:
		_boss_bar_container.visible = false
	_tracked_boss = null


func on_player_revived() -> void:
	# Called when player auto-revives via revive stone — hide death overlay
	if death_screen != null and death_screen.has_method("_hide_death_screen"):
		death_screen._hide_death_screen()
