extends PanelContainer

const MAX_MESSAGES := 100

@onready var chat_log: RichTextLabel = %ChatLog
@onready var chat_input: LineEdit = %ChatInput
@onready var send_button: Button = %SendButton

var _message_history: Array[Dictionary] = []


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

	# Add to history
	_message_history.append({
		"sender": sender,
		"message": message,
		"color": color
	})

	# Trim old messages if exceeding limit
	while _message_history.size() > MAX_MESSAGES:
		_message_history.pop_front()

	# Append only the new message instead of full rebuild
	_append_message(_message_history[-1])


func _append_message(msg_data: Dictionary) -> void:
	if not is_instance_valid(chat_log):
		return
	var color: Color = msg_data.color
	var hex: String = color.to_html(false)
	var safe_sender: String = _escape_chat_bbcode(msg_data.sender)
	var safe_message: String = _escape_chat_bbcode(msg_data.message)
	chat_log.append_text("[color=#" + hex + "][b]" + safe_sender + ":[/b] " + safe_message + "[/color]\n")
	chat_log.scroll_to_line(chat_log.get_line_count())


func _rebuild_chat_log() -> void:
	if not is_instance_valid(chat_log):
		return

	chat_log.clear()
	for msg_data in _message_history:
		_append_message(msg_data)
	chat_log.scroll_to_line(chat_log.get_line_count())


func _escape_chat_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")


func _get_chat_sender_name() -> String:
	if MultiplayerManager.player_ign.strip_edges().is_empty():
		return "You"
	return MultiplayerManager.player_ign.strip_edges()


func _send_current_message() -> void:
	if not is_instance_valid(chat_input):
		return
	var msg := chat_input.text.strip_edges()
	if msg.is_empty():
		return

	var sender_name := _get_chat_sender_name()

	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		MultiplayerManager.send_match_state({
			"type": "chat_message",
			"sender": sender_name,
			"message": msg
		})

	# Show the message locally immediately
	add_message(sender_name, msg)

	chat_input.text = ""
	chat_input.grab_focus()


func _on_send_pressed() -> void:
	_send_current_message()


func _on_chat_submitted(_msg: String) -> void:
	_send_current_message()
