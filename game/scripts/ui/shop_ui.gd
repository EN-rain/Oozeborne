extends Control
class_name ShopUI

## ShopUI - Shop panel for purchasing items

signal closed

@export var item_card_scene: PackedScene

@onready var close_button: Button = %CloseButton
@onready var tabs: TabContainer = %TabContainer
@onready var coins_label: Label = %CoinsLabel
@onready var consumables_grid: GridContainer = %ConsumablesGrid
@onready var upgrades_grid: GridContainer = %UpgradesGrid
@onready var equipment_grid: GridContainer = %EquipmentGrid
@onready var special_grid: GridContainer = %SpecialGrid

var _item_cards: Array[ShopItemCard] = []

func _ready():
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
	_item_cards.clear()

	for item in items:
		var item_card = _create_item_card(item)
		grid.add_child(item_card)

func _update_buy_button_states() -> void:
	# Update existing buttons without rebuilding the entire UI
	var coin_manager := _coin_manager()
	var coins: int = coin_manager.get_coins() if coin_manager != null else 0

	for card in _item_cards:
		if is_instance_valid(card):
			card.refresh_state(coins)


func _create_item_card(item: ShopItem) -> Control:
	if item_card_scene == null:
		push_warning("[ShopUI] item_card_scene is not assigned.")
		return Control.new()
	var coin_manager := _coin_manager()
	var player_coins: int = coin_manager.get_coins() if coin_manager != null else 0
	var card := item_card_scene.instantiate() as ShopItemCard
	card.configure(item, player_coins)
	if not card.buy_requested.is_connected(_on_buy_pressed):
		card.buy_requested.connect(_on_buy_pressed)
	_item_cards.append(card)
	return card


func _on_buy_pressed(item: ShopItem):
	var shop_manager := _shop_manager()
	if shop_manager != null:
		shop_manager.purchase_item(item)


func _on_item_purchased(item: ShopItem, success: bool):
	if success:
		_update_buy_button_states()


func _on_coins_changed(_total: int):
	_update_coins_display()
	_update_buy_button_states()  # Only update buttons, don't rebuild entire UI


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
	if close_button != null:
		close_button.grab_focus.call_deferred()
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
	return CoinManager


func _shop_manager() -> Node:
	return ShopManager
