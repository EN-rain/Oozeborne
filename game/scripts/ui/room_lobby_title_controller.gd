extends Node

@export var title_label_path: NodePath
@export var title_edit_path: NodePath

var _host_name_provider: Callable = Callable()

@onready var title_label: Label = get_node_or_null(title_label_path) as Label
@onready var title_edit: LineEdit = get_node_or_null(title_edit_path) as LineEdit


func setup(host_name_provider: Callable) -> void:
	_host_name_provider = host_name_provider
	if is_instance_valid(title_label):
		if not title_label.gui_input.is_connected(_on_title_label_gui_input):
			title_label.gui_input.connect(_on_title_label_gui_input)
	if is_instance_valid(title_edit):
		if not title_edit.text_submitted.is_connected(_on_title_edit_text_submitted):
			title_edit.text_submitted.connect(_on_title_edit_text_submitted)
		if not title_edit.focus_exited.is_connected(_on_title_edit_focus_exited):
			title_edit.focus_exited.connect(_on_title_edit_focus_exited)
		if not title_edit.gui_input.is_connected(_on_title_edit_gui_input):
			title_edit.gui_input.connect(_on_title_edit_gui_input)
	refresh_title()


func refresh_title() -> void:
	var current_name := get_current_lobby_name()
	if is_instance_valid(title_label):
		title_label.text = current_name
	if is_instance_valid(title_edit):
		title_edit.editable = MultiplayerManager.is_host
		title_edit.placeholder_text = _build_default_lobby_name(_get_host_ign())
		if not title_edit.has_focus():
			title_edit.text = current_name


func broadcast_lobby_name() -> void:
	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		MultiplayerManager.send_match_state({
			"type": "lobby_name",
			"name": get_current_lobby_name()
		})


func get_current_lobby_name() -> String:
	var current_name: String = MultiplayerManager.lobby_name.strip_edges()
	if current_name.is_empty():
		return _build_default_lobby_name(_get_host_ign())
	return current_name


func _get_host_ign() -> String:
	if _host_name_provider.is_valid():
		return str(_host_name_provider.call())
	return "Player"


func _build_default_lobby_name(host_ign: String) -> String:
	var safe_host_ign := host_ign.strip_edges()
	if safe_host_ign.is_empty():
		safe_host_ign = "Player"
	return "%s's Lobby" % safe_host_ign


func _begin_lobby_title_edit() -> void:
	if not MultiplayerManager.is_host or not is_instance_valid(title_edit) or not is_instance_valid(title_label):
		return
	title_edit.text = get_current_lobby_name()
	title_edit.visible = true
	title_label.visible = false
	title_edit.grab_focus()
	title_edit.select_all()


func _finish_lobby_title_edit(cancel: bool = false) -> void:
	if not is_instance_valid(title_edit) or not is_instance_valid(title_label):
		return
	if cancel:
		title_edit.text = get_current_lobby_name()
	else:
		var next_name: String = title_edit.text.strip_edges()
		if next_name.is_empty():
			next_name = _build_default_lobby_name(_get_host_ign())
		MultiplayerManager.lobby_name = next_name
	title_edit.visible = false
	title_label.visible = true
	refresh_title()


func _commit_lobby_title_edit() -> void:
	if not MultiplayerManager.is_host or not is_instance_valid(title_edit) or not title_edit.visible:
		return
	_finish_lobby_title_edit(false)
	broadcast_lobby_name()


func _on_title_label_gui_input(event: InputEvent) -> void:
	if not MultiplayerManager.is_host:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_lobby_title_edit()
		get_viewport().set_input_as_handled()


func _on_title_edit_text_submitted(_new_text: String) -> void:
	_commit_lobby_title_edit()


func _on_title_edit_focus_exited() -> void:
	if is_instance_valid(title_edit) and title_edit.visible:
		_commit_lobby_title_edit()


func _on_title_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_finish_lobby_title_edit(true)
		get_viewport().set_input_as_handled()
