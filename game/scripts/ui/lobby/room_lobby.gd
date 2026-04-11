extends Control


@onready var room_code_button: Button = %RoomCode
@onready var leave_button: Button = %LeaveLobby
@onready var start_button: Button = %StartGame
@onready var select_class_button: Button = %SelectClass
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton
@onready var players_panel: PanelContainer = %Players
@onready var players_title: Label = %PlayersTitle
@onready var players_list: VBoxContainer = %PlayersList
@onready var class_stats_panel: PanelContainer = %ClassStats
@onready var subclass_info_panel: PanelContainer = %SubClassInfo
@onready var lobby_title_label: Label = %Label
@onready var subclass_hint_label: Label = %SubclassHintLabel
@onready var lobby_name_edit: LineEdit = %LobbyNameEdit
@onready var stats_content: RichTextLabel = %StatsContent
@onready var subclass_content: RichTextLabel = %SubclassContent
@onready var hp_value_label: Label = %HPValue
@onready var atk_value_label: Label = %AttackValue
@onready var def_value_label: Label = %DefenseValue
@onready var spd_value_label: Label = %SpeedValue
@onready var crit_value_label: Label = %CritValue
@onready var evade_value_label: Label = %EvadeValue
@onready var hp_card: PanelContainer = %HPCard
@onready var attack_card: PanelContainer = %AttackCard
@onready var defense_card: PanelContainer = %DefenseCard
@onready var speed_card: PanelContainer = %SpeedCard
@onready var crit_card: PanelContainer = %CritCard
@onready var evade_card: PanelContainer = %EvadeCard
@onready var talent_cards: VBoxContainer = %TalentCards
@onready var title_controller = %LobbyTitleController
@onready var carousel_controller = %LobbyCarouselController
@onready var chat_box = %ChatBox
@onready var class_slots: Array[Control] = [%Class1, %Class2, %Class3, %Class4, %Class5]
@onready var party_controller: RoomLobbyPartyController = %LobbyPartyController
@onready var match_flow: RoomLobbyMatchFlow = %LobbyMatchFlow

@export_file("*.tscn") var main_game_scene_path: String = "res://scenes/levels/main.tscn"
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"
@export var join_game_button_text: String = "Join Quest"
@export var responsive_base_resolution: Vector2 = Vector2(1920.0, 1080.0)
@export var responsive_min_scale: float = 0.72
@export var responsive_max_scale: float = 1.35

var _responsive_controls: Array[Control] = []
var _responsive_layout_by_path: Dictionary = {}


func _ready() -> void:
	var refs := {
		"players_title": players_title,
		"players_list": players_list,
		"stats_content": stats_content,
		"subclass_content": subclass_content,
		"hp_value_label": hp_value_label,
		"atk_value_label": atk_value_label,
		"def_value_label": def_value_label,
		"spd_value_label": spd_value_label,
		"crit_value_label": crit_value_label,
		"evade_value_label": evade_value_label,
		"talent_cards": talent_cards,
		"stat_cards": [hp_card, attack_card, defense_card, speed_card, crit_card, evade_card],
	}

	party_controller.setup(
		refs,
		title_controller,
		carousel_controller,
		chat_box,
		class_slots,
		select_class_button,
		left_button,
		right_button,
		start_button
	)
	match_flow.setup(
		room_code_button,
		leave_button,
		start_button,
		main_game_scene_path,
		main_menu_scene_path,
		join_game_button_text,
		party_controller,
		title_controller
	)

	_setup_responsive_layout()

	if MultiplayerManager.match_phase == "in_game":
		match_flow.show_join_game_ui()
		return

	match_flow.enter_lobby()


func _exit_tree() -> void:
	if is_instance_valid(match_flow):
		match_flow.cleanup()


func _on_left_pressed() -> void:
	party_controller.move_left()


func _on_right_pressed() -> void:
	party_controller.move_right()


func _on_select_class_pressed() -> void:
	party_controller.on_select_class_pressed()


func _on_start_pressed() -> void:
	if MultiplayerManager.match_phase == "in_game" and not MultiplayerManager.is_host:
		match_flow.on_join_game_pressed()
		return
	await match_flow.on_start_pressed()


func _on_back_pressed() -> void:
	match_flow.on_back_pressed()


func _on_copy_code_pressed() -> void:
	match_flow.on_copy_code_pressed()


func get_selected_class() -> PlayerClass:
	return party_controller.get_selected_class()


func get_selected_subclass() -> PlayerClass:
	return null


func _get_player_class_for_name(selected_name: String) -> PlayerClass:
	return party_controller.get_player_class_for_name(selected_name)


func _get_slime_scene_path_for_class(selected_name: String) -> String:
	return party_controller.get_slime_scene_path_for_class(selected_name)


func _setup_responsive_layout() -> void:
	_responsive_controls.clear()
	_responsive_layout_by_path.clear()
	_responsive_controls.assign([
		room_code_button,
		leave_button,
		start_button,
		select_class_button,
		left_button,
		right_button,
		chat_box,
		players_panel,
		class_stats_panel,
		subclass_info_panel,
		lobby_title_label,
		lobby_name_edit,
	])
	for slot in class_slots:
		_responsive_controls.append(slot)
	for control in _responsive_controls:
		if is_instance_valid(control):
			_store_responsive_layout(control)
	if not get_viewport().size_changed.is_connected(_apply_responsive_layout):
		get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _store_responsive_layout(control: Control) -> void:
	_responsive_layout_by_path[String(control.get_path())] = {
		"offset_left": control.offset_left,
		"offset_top": control.offset_top,
		"offset_right": control.offset_right,
		"offset_bottom": control.offset_bottom,
		"scale_x": control.scale.x,
		"scale_y": control.scale.y,
	}


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var base_width: float = maxf(responsive_base_resolution.x, 1.0)
	var base_height: float = maxf(responsive_base_resolution.y, 1.0)
	var horizontal_scale: float = minf(viewport_size.x / base_width, 1.0)
	var vertical_scale: float = minf(viewport_size.y / base_height, 1.0)
	var uniform_scale: float = clampf(minf(horizontal_scale, vertical_scale), responsive_min_scale, 1.0)
	for control in _responsive_controls:
		if not is_instance_valid(control):
			continue
		var key: String = String(control.get_path())
		if not _responsive_layout_by_path.has(key):
			continue
		var base_layout: Dictionary = _responsive_layout_by_path[key]
		control.offset_left = float(base_layout["offset_left"]) * uniform_scale
		control.offset_right = float(base_layout["offset_right"]) * uniform_scale
		control.offset_top = float(base_layout["offset_top"]) * uniform_scale
		control.offset_bottom = float(base_layout["offset_bottom"]) * uniform_scale
		control.scale = Vector2(
			float(base_layout["scale_x"]) * uniform_scale,
			float(base_layout["scale_y"]) * uniform_scale
		)
