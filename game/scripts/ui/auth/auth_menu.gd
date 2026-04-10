extends Control

@onready var auth_tabs: TabContainer = %AuthTabs
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var login_tab: Control = %LoginTab
@onready var register_tab: Control = %RegisterTab
@onready var auth_card: Control = %VBox
@onready var login_email_input: LineEdit = %LoginEmailInput
@onready var login_password_input: LineEdit = %LoginPasswordInput
@onready var login_button: Button = %LoginButton
@onready var register_email_input: LineEdit = %RegisterEmailInput
@onready var register_password_input: LineEdit = %RegisterPasswordInput
@onready var register_confirm_input: LineEdit = %RegisterConfirmInput
@onready var register_button: Button = %RegisterButton
@onready var status_label: Label = %StatusLabel

@export_file("*.tscn") var main_menu_scene_path: String
@export var login_tab_title: String = "Login"
@export var register_tab_title: String = "Register"
@export var default_status_color: Color = Color(0.62, 0.66, 0.8, 0.85)
@export var checking_saved_session_text: String = "Checking saved session..."
@export var checking_saved_session_color: Color = Color(0.55, 0.75, 0.95)
@export var saved_session_restored_text: String = "Saved session restored. You can sign in or continue."
@export var sign_in_prompt_text: String = "Sign in or create an account"
@export var success_status_color: Color = Color(0.4, 0.78, 0.55)
@export var error_status_color: Color = Color(0.9, 0.4, 0.4)
@export var signing_in_text: String = "Signing in..."
@export var login_success_text: String = "Login successful. Entering main menu..."
@export var creating_account_text: String = "Creating account..."
@export var create_account_status_color: Color = Color(0.7, 0.55, 0.95)
@export var account_created_text: String = "Account created. Please sign in."
@export var invalid_email_text: String = "Enter a valid email address"
@export var password_too_short_text: String = "Password must be at least 6 characters"
@export var passwords_mismatch_text: String = "Passwords do not match"

var _busy: bool = false
var _auth_interacted: bool = false
var _last_tab_index: int = 0
var _pending_scene_change: bool = false


func _ready() -> void:
	_last_tab_index = auth_tabs.current_tab
	_setup_animation_player()
	_prepare_auth_tabs()
	call_deferred("_attempt_restore_session")


func _mark_auth_interacted(_text: String = "") -> void:
	_auth_interacted = true


func _prepare_auth_tabs() -> void:
	auth_tabs.set_tab_title(0, login_tab_title)
	auth_tabs.set_tab_title(1, register_tab_title)
	_pending_scene_change = false
	auth_card.modulate = Color.WHITE
	auth_card.scale = Vector2.ONE
	login_tab.modulate = Color.WHITE
	register_tab.modulate = Color.WHITE
	login_tab.scale = Vector2.ONE
	register_tab.scale = Vector2.ONE
	status_label.modulate = Color.WHITE


func _setup_animation_player() -> void:
	if animation_player == null:
		return

	var library: AnimationLibrary = null
	if animation_player.has_animation_library(&""):
		library = animation_player.get_animation_library(&"")
	else:
		library = AnimationLibrary.new()
		animation_player.add_animation_library(&"", library)

	_add_tab_animation(library, &"tab_login")
	_add_tab_animation(library, &"tab_register")
	_add_main_menu_animation(library, &"to_main_menu")


func _add_tab_animation(library: AnimationLibrary, animation_name: StringName) -> void:
	if library.has_animation(animation_name):
		library.remove_animation(animation_name)

	var animation := Animation.new()
	animation.length = 0.22
	var target_node: Control = login_tab if animation_name == &"tab_login" else register_tab

	var modulate_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, _animation_property_path(target_node, "modulate"))
	animation.track_insert_key(modulate_track, 0.0, Color(1.0, 1.0, 1.0, 0.0))
	animation.track_insert_key(modulate_track, 0.22, Color.WHITE)

	var scale_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, _animation_property_path(target_node, "scale"))
	animation.track_insert_key(scale_track, 0.0, Vector2(0.985, 0.985))
	animation.track_insert_key(scale_track, 0.22, Vector2.ONE)

	var status_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(status_track, _animation_property_path(status_label, "modulate"))
	animation.track_insert_key(status_track, 0.0, Color(1.0, 1.0, 1.0, 0.55))
	animation.track_insert_key(status_track, 0.16, Color.WHITE)

	library.add_animation(animation_name, animation)


func _add_main_menu_animation(library: AnimationLibrary, animation_name: StringName) -> void:
	if library.has_animation(animation_name):
		library.remove_animation(animation_name)

	var animation := Animation.new()
	animation.length = 0.3

	var modulate_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(modulate_track, _animation_property_path(auth_card, "modulate"))
	animation.track_insert_key(modulate_track, 0.0, Color.WHITE)
	animation.track_insert_key(modulate_track, 0.3, Color(1.0, 1.0, 1.0, 0.0))

	var scale_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, _animation_property_path(auth_card, "scale"))
	animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
	animation.track_insert_key(scale_track, 0.3, Vector2(0.97, 0.97))

	library.add_animation(animation_name, animation)


func _animation_property_path(target: Node, property: String) -> NodePath:
	return NodePath("%s:%s" % [animation_player.get_path_to(target), property])


func _set_busy(busy: bool) -> void:
	_busy = busy
	login_button.disabled = busy
	register_button.disabled = busy
	login_email_input.editable = not busy
	login_password_input.editable = not busy
	register_email_input.editable = not busy
	register_password_input.editable = not busy
	register_confirm_input.editable = not busy


func _set_status(text: String, color: Color = default_status_color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)


func _on_auth_tab_changed(tab_index: int) -> void:
	_mark_auth_interacted()
	_play_tab_transition(tab_index)
	_last_tab_index = tab_index


func _play_tab_transition(tab_index: int) -> void:
	if animation_player == null:
		return
	var animation_name := "tab_register" if tab_index == 1 else "tab_login"
	if animation_player.has_animation(animation_name):
		_reset_auth_visual_state()
		animation_player.play(animation_name)


func _reset_auth_visual_state() -> void:
	login_tab.modulate = Color.WHITE
	register_tab.modulate = Color.WHITE
	login_tab.scale = Vector2.ONE
	register_tab.scale = Vector2.ONE
	login_tab.pivot_offset = login_tab.size * 0.5
	register_tab.pivot_offset = register_tab.size * 0.5
	auth_card.pivot_offset = auth_card.size * 0.5
	status_label.modulate = Color.WHITE


func _validate_login_fields() -> Dictionary:
	var email := login_email_input.text.strip_edges().to_lower()
	var password := login_password_input.text
	if email.is_empty() or not email.contains("@"):
		return {"valid": false, "error": invalid_email_text}
	if password.length() < 6:
		return {"valid": false, "error": password_too_short_text}
	return {"valid": true, "email": email, "password": password}


func _validate_register_fields() -> Dictionary:
	var email := register_email_input.text.strip_edges().to_lower()
	var password := register_password_input.text
	var confirm_password := register_confirm_input.text
	if email.is_empty() or not email.contains("@"):
		return {"valid": false, "error": invalid_email_text}
	if password.length() < 6:
		return {"valid": false, "error": password_too_short_text}
	if password != confirm_password:
		return {"valid": false, "error": passwords_mismatch_text}
	return {"valid": true, "email": email, "password": password}


func _go_to_main_menu() -> void:
	call_deferred("_deferred_go_to_main_menu")


func _go_to_main_menu_with_transition() -> void:
	if _pending_scene_change:
		return

	_set_busy(true)
	_pending_scene_change = true
	_reset_auth_visual_state()
	if animation_player != null and animation_player.has_animation("to_main_menu"):
		animation_player.play("to_main_menu")
		return
	_go_to_main_menu()


func _deferred_go_to_main_menu() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(main_menu_scene_path)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"to_main_menu" and _pending_scene_change:
		_pending_scene_change = false
		_reset_auth_visual_state()
		_go_to_main_menu()


func _attempt_restore_session() -> void:
	if MultiplayerManager.is_authenticated():
		_go_to_main_menu()
		return
	
	_set_status(checking_saved_session_text, checking_saved_session_color)
	var restore_result = await MultiplayerManager.restore_saved_session()
	if _auth_interacted:
		if restore_result.get("success", false):
			_set_status(saved_session_restored_text, success_status_color)
		else:
			_set_status(sign_in_prompt_text, default_status_color)
		return
	if restore_result.get("success", false):
		_go_to_main_menu()
	else:
		_set_status(sign_in_prompt_text, default_status_color)


func _on_login_submitted(_text: String) -> void:
	_on_login_pressed()


func _on_register_submitted(_text: String) -> void:
	_on_register_pressed()


func _on_login_pressed() -> void:
	_mark_auth_interacted()
	var validation = _validate_login_fields()
	if not validation.get("valid", false):
		_set_status(validation.get("error", "Invalid login data"), error_status_color)
		return
	
	# Clear any existing session before logging in with new credentials
	MultiplayerManager.clear_session()
	
	_set_busy(true)
	_set_status(signing_in_text, checking_saved_session_color)
	var login_result = await MultiplayerManager.login_with_email(validation["email"], validation["password"])
	if login_result.get("success", false):
		_set_status(login_success_text, success_status_color)
		_go_to_main_menu_with_transition()
	else:
		_set_busy(false)
		_set_status(login_result.get("error", "Login failed"), error_status_color)


func _on_register_pressed() -> void:
	_mark_auth_interacted()
	var validation = _validate_register_fields()
	if not validation.get("valid", false):
		_set_status(validation.get("error", "Invalid registration data"), error_status_color)
		return
	
	_set_busy(true)
	_set_status(creating_account_text, create_account_status_color)
	var register_result = await MultiplayerManager.register_with_email(validation["email"], validation["password"], "")
	_set_busy(false)
	if register_result.get("success", false):
		login_email_input.text = validation["email"]
		login_password_input.text = ""
		register_password_input.text = ""
		register_confirm_input.text = ""
		auth_tabs.current_tab = 0
		login_password_input.grab_focus()
		_set_status(account_created_text, success_status_color)
	else:
		_set_status(register_result.get("error", "Registration failed"), error_status_color)
