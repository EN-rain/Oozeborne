extends Control
class_name ShopUI

## ShopUI - Shop panel for purchasing items

@onready var close_button: Button = $Panel/VBox/Header/CloseButton
@onready var tabs: TabContainer = $Panel/VBox/TabContainer
@onready var coins_label: Label = $Panel/VBox/Header/CoinsLabel

var _selected_item: ShopItem = null
var _selected_category: String = "consumables"

# Category grids
var consumables_grid: GridContainer
var upgrades_grid: GridContainer
var equipment_grid: GridContainer
var special_grid: GridContainer


func _ready():
	_setup_ui()
	_connect_signals()
	_refresh_shop()


func _setup_ui():
	# Create tab content
	for i in range(tabs.get_child_count()):
		var child = tabs.get_child(i)
		match child.name:
			"Consumables":
				consumables_grid = _create_item_grid(child)
			"Upgrades":
				upgrades_grid = _create_item_grid(child)
			"Equipment":
				equipment_grid = _create_item_grid(child)
			"Special":
				special_grid = _create_item_grid(child)


func _create_item_grid(parent: Control) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	return grid


func _connect_signals():
	close_button.pressed.connect(_on_close_pressed)
	CoinManager.coins_changed.connect(_on_coins_changed)
	ShopManager.item_purchased.connect(_on_item_purchased)


func _refresh_shop():
	_populate_grid(consumables_grid, ShopManager.consumables)
	_populate_grid(upgrades_grid, ShopManager.upgrades)
	_populate_grid(equipment_grid, ShopManager.equipment)
	_populate_grid(special_grid, ShopManager.special_items)
	_update_coins_display()


func _populate_grid(grid: GridContainer, items: Array):
	# Clear existing
	for child in grid.get_children():
		child.queue_free()
	
	for item in items:
		var item_card = _create_item_card(item)
		grid.add_child(item_card)


func _create_item_card(item: ShopItem) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 100)
	
	# Pixel-art card style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.14, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.28, 0.45, 0.55)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.display_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	vbox.add_child(name_label)
	
	# Effect description
	var effect_label = Label.new()
	effect_label.text = item.get_effect_description()
	effect_label.add_theme_font_size_override("font_size", 11)
	effect_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.75))
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(effect_label)
	
	# Price
	var price_label = Label.new()
	price_label.text = "%d coins" % item.price
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	vbox.add_child(price_label)
	
	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Buy"
	buy_btn.custom_minimum_size = Vector2(80, 25)
	
	# Style button
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.45, 0.28)
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color(0.1, 0.35, 0.2)
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.corner_radius_bottom_left = 4
	buy_btn.add_theme_stylebox_override("normal", btn_normal)
	
	# Disable if can't afford
	if not item.can_afford(CoinManager.get_coins()):
		buy_btn.disabled = true
		btn_normal.bg_color = Color(0.15, 0.12, 0.2, 0.5)
	
	# Disable if already owned (permanent upgrades)
	if item.item_type == ShopItem.ItemType.PERMANENT_UPGRADE and item.owned:
		buy_btn.text = "Owned"
		buy_btn.disabled = true
		btn_normal.bg_color = Color(0.1, 0.3, 0.2)
	
	buy_btn.pressed.connect(_on_buy_pressed.bind(item))
	vbox.add_child(buy_btn)
	
	return card


func _on_buy_pressed(item: ShopItem):
	ShopManager.purchase_item(item)


func _on_item_purchased(item: ShopItem, success: bool):
	if success:
		_refresh_shop()


func _on_coins_changed(total: int):
	_update_coins_display()
	_refresh_shop()


func _update_coins_display():
	if coins_label:
		coins_label.text = "Coins: %d" % CoinManager.get_coins()


func _on_close_pressed():
	hide()
	ShopManager.notify_shop_closed()


func open():
	show()
	_refresh_shop()
	ShopManager.notify_shop_opened()
