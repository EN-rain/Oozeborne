extends Control

## Save Slots UI - Shows 5 save slots with save/load/delete functionality

signal slot_loaded(slot: int)
signal closed()

@onready var slot_container: VBoxContainer = %SlotContainer
@onready var close_button: Button = %CloseButton
@onready var status_label: Label = %StatusLabel

var _busy: bool = false


func _ready() -> void:
	_refresh_slots()


func _refresh_slots() -> void:
	if not MultiplayerManager.is_authenticated():
		_set_status("Not authenticated - login required", Color(0.9, 0.4, 0.4))
		return
	_set_status("Loading save slots...", Color(0.55, 0.75, 0.95))
	_busy = true
	var result = await CloudSaveManager.load_slots()
	_busy = false
	if not result.get("success", false):
		_set_status("Failed to load slots: %s" % str(result.get("error", "")), Color(0.9, 0.4, 0.4))
		return
	_build_slot_cards()
	_set_status("Select a slot to save or load", Color(0.6, 0.7, 0.8))


func _build_slot_cards() -> void:
	# Clear existing cards
	for child in slot_container.get_children():
		child.queue_free()

	var summaries := CloudSaveManager.get_all_slot_summaries()
	for i in range(summaries.size()):
		var summary: Dictionary = summaries[i]
		var slot_num := i + 1
		var card := _create_slot_card(slot_num, summary)
		slot_container.add_child(card)


func _create_slot_card(slot_num: int, summary: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 72)

	# Dark panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.9)
	style.border_color = Color(0.3, 0.25, 0.4, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	# Slot number
	var slot_label := Label.new()
	slot_label.text = "Slot %d" % slot_num
	slot_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35, 1))
	slot_label.add_theme_font_size_override("font_size", 16)
	slot_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(slot_label)

	# Info section
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var is_empty := summary.is_empty()

	if is_empty:
		var empty_label := Label.new()
		empty_label.text = "Empty Slot"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.7))
		empty_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(empty_label)
	else:
		var class_level := Label.new()
		class_level.text = "%s  Lv.%d  Round %d" % [
			str(summary.get("class_name", "—")),
			int(summary.get("level", 1)),
			int(summary.get("round", 1))
		]
		class_level.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		class_level.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(class_level)

		var detail := Label.new()
		var coins := int(summary.get("coins", 0))
		var saved_at := str(summary.get("saved_at", ""))
		detail.text = "Coins: %d  |  %s" % [coins, saved_at]
		detail.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7, 0.85))
		detail.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(detail)

	# Buttons
	var btn_box := HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 6)
	btn_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(btn_box)

	# Save button (always available - overwrites or creates)
	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.add_theme_font_size_override("font_size", 13)
	if is_empty:
		save_btn.tooltip_text = "Save current game to this slot"
	else:
		save_btn.tooltip_text = "Overwrite this slot with current game"
	save_btn.pressed.connect(_on_save_slot.bind(slot_num))
	btn_box.add_child(save_btn)

	if not is_empty:
		# Load button
		var load_btn := Button.new()
		load_btn.text = "Load"
		load_btn.add_theme_font_size_override("font_size", 13)
		load_btn.tooltip_text = "Load save from this slot"
		load_btn.pressed.connect(_on_load_slot.bind(slot_num))
		btn_box.add_child(load_btn)

		# Delete button
		var delete_btn := Button.new()
		delete_btn.text = "✕"
		delete_btn.add_theme_font_size_override("font_size", 13)
		delete_btn.tooltip_text = "Delete this save slot"
		delete_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		delete_btn.pressed.connect(_on_delete_slot.bind(slot_num))
		btn_box.add_child(delete_btn)

	return card


func _on_save_slot(slot: int) -> void:
	if _busy:
		return
	_busy = true
	_set_status("Saving to slot %d..." % slot, Color(0.55, 0.75, 0.95))
	var result = await CloudSaveManager.save_to_slot(slot)
	_busy = false
	if result.get("success", false):
		_set_status("Saved to slot %d!" % slot, Color(0.4, 0.78, 0.55))
		_build_slot_cards()
	else:
		_set_status("Save failed: %s" % str(result.get("error", "")), Color(0.9, 0.4, 0.4))


func _on_load_slot(slot: int) -> void:
	if _busy:
		return
	_busy = true
	_set_status("Loading slot %d..." % slot, Color(0.55, 0.75, 0.95))
	var result = await CloudSaveManager.load_from_slot(slot)
	_busy = false
	if result.get("success", false):
		_set_status("Loaded slot %d!" % slot, Color(0.4, 0.78, 0.55))
		slot_loaded.emit(slot)
	else:
		_set_status("Load failed: %s" % str(result.get("error", "")), Color(0.9, 0.4, 0.4))


func _on_delete_slot(slot: int) -> void:
	if _busy:
		return
	_busy = true
	_set_status("Deleting slot %d..." % slot, Color(0.9, 0.6, 0.3))
	var result = await CloudSaveManager.delete_slot(slot)
	_busy = false
	if result.get("success", false):
		_set_status("Slot %d deleted" % slot, Color(0.4, 0.78, 0.55))
		_build_slot_cards()
	else:
		_set_status("Delete failed: %s" % str(result.get("error", "")), Color(0.9, 0.4, 0.4))


func _on_auto_save_pressed() -> void:
	if _busy:
		return
	_busy = true
	_set_status("Quick saving...", Color(0.55, 0.75, 0.95))
	var result = await CloudSaveManager.auto_save()
	_busy = false
	if result.get("success", false):
		var slot := int(result.get("slot", 0))
		_set_status("Quick saved to slot %d!" % slot, Color(0.4, 0.78, 0.55))
		_build_slot_cards()
	else:
		_set_status("Quick save failed: %s" % str(result.get("error", "")), Color(0.9, 0.4, 0.4))


func _on_close_pressed() -> void:
	closed.emit()
	hide()


func _set_status(text: String, color: Color = Color(0.6, 0.7, 0.8)) -> void:
	if status_label != null:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)
