extends PanelContainer
class_name ClassSelectionMainSlot

signal slot_pressed(slot: ClassSelectionMainSlot)
signal slot_hovered(slot: ClassSelectionMainSlot)
signal slot_unhovered(slot: ClassSelectionMainSlot)

@export var icon_path: NodePath
@export var title_label_path: NodePath
@export var empty_title_text: String = "Unavailable"
@export var disabled_slot_modulate: Color = Color(0.55, 0.55, 0.55, 0.72)

var player_class: PlayerClass = null

@onready var _icon: TextureRect = get_node_or_null(icon_path) as TextureRect
@onready var _title_label: Label = get_node_or_null(title_label_path) as Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func configure(next_class: PlayerClass) -> void:
	player_class = next_class
	if _icon != null:
		_icon.modulate = Color.WHITE if next_class != null else Color(1, 1, 1, 0.18)
	if _title_label != null:
		_title_label.text = next_class.display_name if next_class != null else empty_title_text
	modulate = Color.WHITE if next_class != null else disabled_slot_modulate


func set_state_color(color: Color) -> void:
	modulate = color if player_class != null else disabled_slot_modulate


func _on_gui_input(event: InputEvent) -> void:
	if player_class == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		slot_pressed.emit(self)
		accept_event()


func _on_mouse_entered() -> void:
	if player_class != null:
		slot_hovered.emit(self)


func _on_mouse_exited() -> void:
	if player_class != null:
		slot_unhovered.emit(self)
