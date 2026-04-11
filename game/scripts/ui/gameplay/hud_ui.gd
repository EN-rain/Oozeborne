extends CanvasLayer

@onready var control_panel: HudControlPanel = $Control
@onready var player_panel: HudPlayerPanel = $Control/PlayerStats
@onready var minimap: HudMinimap = %Map
@onready var death_screen: Control = %Death
@onready var skills_root: HudSkillBar = %Skills
@onready var stats_panel: HudStatsPanel = $Stats
@onready var chat_box: Control = %ChatBox

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
		death_screen.show_death_screen(score, killer_name)


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
