extends PanelContainer

@onready var chat_log: RichTextLabel = %ChatLog
@onready var chat_input: LineEdit = %ChatInput
@onready var send_button: Button = %SendButton


func _ready() -> void:
	pass


func focus_input() -> void:
	if is_instance_valid(chat_input):
		chat_input.grab_focus()


func send_current_message() -> void:
	_send_current_message()


func add_message(sender: String, message: String, color: Color = Color(0.7, 0.65, 0.85)) -> void:
	if not is_instance_valid(chat_log):
		return
	var hex := color.to_html(false)
	var safe_sender := _escape_chat_bbcode(sender)
	var safe_message := _escape_chat_bbcode(message)
	chat_log.append_text("[color=#" + hex + "][b]" + safe_sender + ":[/b] " + safe_message + "[/color]\n")


func _escape_chat_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")


func _get_chat_sender_name() -> String:
	if MultiplayerManager.player_ign.strip_edges().is_empty():
		return "You"
	return MultiplayerManager.player_ign


func _send_current_message() -> void:
	if not is_instance_valid(chat_input):
		return
	var msg := chat_input.text.strip_edges()
	if msg.is_empty():
		return

	var sender_name := _get_chat_sender_name()
	add_message(sender_name, msg, Color(0.5, 0.75, 0.95))

	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		MultiplayerManager.send_match_state({
			"type": "chat_message",
			"sender": sender_name,
			"message": msg
		})

	chat_input.text = ""
	chat_input.grab_focus()


func _on_send_pressed() -> void:
	_send_current_message()


func _on_chat_submitted(_msg: String) -> void:
	_send_current_message()
