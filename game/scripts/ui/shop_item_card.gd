extends PanelContainer
class_name ShopItemCard

signal buy_requested(item: ShopItem)

const AFFORDABLE_COLOR := Color(0.15, 0.45, 0.28)
const UNAFFORDABLE_COLOR := Color(0.15, 0.12, 0.2, 0.5)
const OWNED_COLOR := Color(0.1, 0.3, 0.2)

@export var affordable_button_style: StyleBoxFlat
@export var unaffordable_button_style: StyleBoxFlat
@export var owned_button_style: StyleBoxFlat
@export var buy_button_text: String = "Buy"
@export var owned_button_text: String = "Owned"
@export var affordable_fallback_color: Color = AFFORDABLE_COLOR
@export var unaffordable_fallback_color: Color = UNAFFORDABLE_COLOR
@export var owned_fallback_color: Color = OWNED_COLOR

@onready var name_label: Label = %NameLabel
@onready var effect_label: Label = %EffectLabel
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

var _item: ShopItem


func configure(item: ShopItem, player_coins: int) -> void:
	_item = item
	var item_name_label := _get_name_label()
	if item_name_label != null:
		item_name_label.text = item.display_name

	var item_effect_label := _get_effect_label()
	if item_effect_label != null:
		item_effect_label.text = item.get_effect_description()

	var item_price_label := _get_price_label()
	if item_price_label != null:
		item_price_label.text = "%d coins" % item.price

	_refresh_state(player_coins)


func get_item() -> ShopItem:
	return _item


func refresh_state(player_coins: int) -> void:
	_refresh_state(player_coins)


func _refresh_state(player_coins: int) -> void:
	var button := _get_buy_button()
	if button == null:
		return

	if _item == null:
		button.text = buy_button_text
		button.disabled = true
		return

	if _item.item_type == ShopItem.ItemType.PERMANENT_UPGRADE and _item.owned:
		button.text = owned_button_text
		button.disabled = true
		_apply_button_style(owned_button_style, owned_fallback_color)
		return

	button.text = buy_button_text
	var can_afford := _item.can_afford(player_coins)
	button.disabled = not can_afford
	_apply_button_style(affordable_button_style if can_afford else unaffordable_button_style, affordable_fallback_color if can_afford else unaffordable_fallback_color)


func _apply_button_style(style: StyleBoxFlat, fallback_color: Color) -> void:
	var button := _get_buy_button()
	if button == null:
		return
	if style != null:
		button.add_theme_stylebox_override("normal", style)
		return

	push_warning("[ShopItemCard] Missing button style assignment for color %s." % fallback_color)


func _on_buy_pressed() -> void:
	if _item != null:
		buy_requested.emit(_item)


func _get_name_label() -> Label:
	if name_label == null:
		name_label = get_node_or_null("%NameLabel") as Label
	return name_label


func _get_effect_label() -> Label:
	if effect_label == null:
		effect_label = get_node_or_null("%EffectLabel") as Label
	return effect_label


func _get_price_label() -> Label:
	if price_label == null:
		price_label = get_node_or_null("%PriceLabel") as Label
	return price_label


func _get_buy_button() -> Button:
	if buy_button == null:
		buy_button = get_node_or_null("%BuyButton") as Button
	return buy_button
