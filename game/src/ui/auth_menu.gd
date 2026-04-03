extends Control

@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput
@onready var login_button: Button = %LoginButton
@onready var register_button: Button = %RegisterButton
@onready var status_label: Label = %StatusLabel

const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"

var _busy: bool = false

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	call_deferred("_attempt_restore_session")

func _set_busy(busy: bool) -> void:
	_busy = busy
	login_button.disabled = busy
	register_button.disabled = busy
	email_input.editable = not busy
	password_input.editable = not busy

func _set_status(text: String, color: Color = Color(0.62, 0.66, 0.8, 0.85)) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

func _validate_auth_fields() -> Dictionary:
	var email = email_input.text.strip_edges().to_lower()
	var password = password_input.text
	if email.is_empty() or not email.contains("@"):
		return {"valid": false, "error": "Enter a valid email address"}
	if password.length() < 6:
		return {"valid": false, "error": "Password must be at least 6 characters"}
	return {"valid": true, "email": email, "password": password}

func _go_to_main_menu() -> void:
	call_deferred("_deferred_go_to_main_menu")

func _deferred_go_to_main_menu() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _attempt_restore_session() -> void:
	if MultiplayerManager.is_authenticated():
		_go_to_main_menu()
		return

	_set_busy(true)
	_set_status("Checking saved session...", Color(0.55, 0.75, 0.95))
	var restore_result = await MultiplayerManager.restore_saved_session()
	_set_busy(false)
	if restore_result.get("success", false):
		_go_to_main_menu()
	else:
		_set_status("Sign in or create an account", Color(0.62, 0.66, 0.8, 0.85))

func _on_login_pressed() -> void:
	var validation = _validate_auth_fields()
	if not validation.get("valid", false):
		_set_status(validation.get("error", "Invalid login data"), Color(0.9, 0.4, 0.4))
		return

	_set_busy(true)
	_set_status("Signing in...", Color(0.55, 0.75, 0.95))
	var login_result = await MultiplayerManager.login_with_email(validation["email"], validation["password"])
	_set_busy(false)
	if login_result.get("success", false):
		_go_to_main_menu()
	else:
		_set_status(login_result.get("error", "Login failed"), Color(0.9, 0.4, 0.4))

func _on_register_pressed() -> void:
	var validation = _validate_auth_fields()
	if not validation.get("valid", false):
		_set_status(validation.get("error", "Invalid registration data"), Color(0.9, 0.4, 0.4))
		return

	_set_busy(true)
	_set_status("Creating account...", Color(0.7, 0.55, 0.95))
	var register_result = await MultiplayerManager.register_with_email(validation["email"], validation["password"], "")
	_set_busy(false)
	if register_result.get("success", false):
		_go_to_main_menu()
	else:
		_set_status(register_result.get("error", "Registration failed"), Color(0.9, 0.4, 0.4))
