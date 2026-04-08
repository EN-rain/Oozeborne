extends Control
class_name ShopUI

## ShopUI - Shop panel for purchasing items

signal closed

@onready var close_button: Button = %CloseButton
@onready var tabs: TabContainer = %TabContainer
@onready var coins_label: Label = %CoinsLabel
@onready var consumables_grid: GridContainer = %ConsumablesGrid
@onready var upgrades_grid: GridContainer = %UpgradesGrid
@onready var equipment_grid: GridContainer = %EquipmentGrid
@onready var special_grid: GridContainer = %SpecialGrid


func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_connect_signals()
	_refresh_shop()


func _connect_signals():
	var coin_manager := _coin_manager()
	if coin_manager != null and not coin_manager.coins_changed.is_connected(_on_coins_changed):
		coin_manager.coins_changed.connect(_on_coins_changed)
	var shop_manager := _shop_manager()
	if shop_manager != null and not shop_manager.item_purchased.is_connected(_on_item_purchased):
		shop_manager.item_purchased.connect(_on_item_purchased)


func _refresh_shop():
	var shop_manager := _shop_manager()
	if shop_manager == null:
		return
	_populate_grid(consumables_grid, shop_manager.consumables)
	_populate_grid(upgrades_grid, shop_manager.upgrades)
	_populate_grid(equipment_grid, shop_manager.equipment)
	_populate_grid(special_grid, shop_manager.special_items)
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
	var coin_manager := _coin_manager()
	if coin_manager != null and not item.can_afford(coin_manager.get_coins()):
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
	var shop_manager := _shop_manager()
	if shop_manager != null:
		shop_manager.purchase_item(item)


func _on_item_purchased(_item: ShopItem, success: bool):
	if success:
		_refresh_shop()


func _on_coins_changed(_total: int):
	_update_coins_display()
	_refresh_shop()


func _update_coins_display():
	if not is_instance_valid(coins_label):
		return
	var coin_manager := _coin_manager()
	coins_label.text = "Coins: %d" % (coin_manager.get_coins() if coin_manager != null else 0)


func _on_close_pressed():
	close()


func open():
	show()
	_refresh_shop()
	var shop_manager := _shop_manager()
	if shop_manager != null:
		shop_manager.notify_shop_opened()


func close():
	if not visible:
		return
	hide()
	var shop_manager := _shop_manager()
	if shop_manager != null:
		shop_manager.notify_shop_closed()
	closed.emit()


func _coin_manager() -> Node:
	var tree := get_tree()
	return tree.root.get_node_or_null("CoinManager") if tree != null and tree.root != null else null


func _shop_manager() -> Node:
	var tree := get_tree()
	return tree.root.get_node_or_null("ShopManager") if tree != null and tree.root != null else null
