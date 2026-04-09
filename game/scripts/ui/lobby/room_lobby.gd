extends Control


@onready var room_code_button: Button = %RoomCode
@onready var leave_button: Button = %LeaveLobby
@onready var start_button: Button = %StartGame
@onready var select_class_button: Button = %SelectClass
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton
@onready var players_title: Label = %PlayersTitle
@onready var players_list: VBoxContainer = %PlayersList
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
@onready var power_fill: ColorRect = %PowerFill
@onready var power_rank_label: Label = %PowerRank
@onready var talent_cards: VBoxContainer = %TalentCards
@onready var title_controller = %LobbyTitleController
@onready var carousel_controller = %LobbyCarouselController
@onready var chat_box = %ChatBox
@onready var class_slots: Array[Control] = [%Class1, %Class2, %Class3, %Class4, %Class5]
@onready var party_controller: RoomLobbyPartyController = %LobbyPartyController
@onready var match_flow: RoomLobbyMatchFlow = %LobbyMatchFlow

@export_file("*.tscn") var main_game_scene_path: String
@export_file("*.tscn") var main_menu_scene_path: String
@export var join_game_button_text: String = "Join Quest"


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
		"power_fill": power_fill,
		"power_rank_label": power_rank_label,
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
