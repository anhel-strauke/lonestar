extends Node


var _buttons: Array = []
var selected_item_name: String setget set_selected_item

func _ready():
	pass


func set_buttons(new_buttons: Array) -> void:
	for button in _buttons:
		button.disconnect("selected", self, "_on_inventory_item_selected")
	_buttons = new_buttons
	for button in _buttons:
		button.connect("selected", self, "_on_inventory_item_selected")


func update_inventory() -> void:
	for button in _buttons:
		button.item_name = ""
	var has_selected = false
	for i in len(Game.inventory.items):
		if i >= len(_buttons):
			break
		var item = Game.inventory.items[i]
		var button = _buttons[i]
		button.item_name = item
		if selected_item_name == item:
			button.pressed = true
			has_selected = true
		else:
			button.pressed = false
	if not has_selected:
		set_selected_item("")


func _on_inventory_item_selected(item_name: String) -> void:
	set_selected_item(item_name)
	Interface.set_inventory_cursor(item_name)


func deselect_all() -> void:
	set_selected_item("")


func find_first_available_button() -> Node2D:
	for button in _buttons:
		if not button.item_name:
			return button
	return null


func set_selected_item(item_name: String) -> void:
	selected_item_name = item_name
	if Game.inventory.items.find(item_name) < 0:
		selected_item_name = ""
	for button in _buttons:
		button.pressed = button.item_name == selected_item_name and selected_item_name
