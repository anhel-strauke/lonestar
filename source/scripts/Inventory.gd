extends Node

var items: Array = []
var flying_items: Array = []

const _items_data: Dictionary = {
	"fuse": {
		icon_index = 1,
		title = "Fuse",
	}
}


signal inventory_changed()


func add_flying_item(item_name: String) -> void:
	if items.find(item_name) < 0:
		if item_name in _items_data:
			flying_items.append(item_name)
			emit_signal("inventory_changed")
		else:
			printerr("ERROR: Trying to add item \"" + item_name + "\" to the Inventory, but item is unknown")


func add_item(item_name: String) -> void:
	if items.find(item_name) < 0:
		if item_name in _items_data:
			items.append(item_name)
			emit_signal("inventory_changed")
		else:
			printerr("ERROR: Trying to add item \"" + item_name + "\" to the Inventory, but item is unknown")


func merge_flying_items() -> void:
	for fitem in flying_items:
		if items.find(fitem) < 0:
			items.append(fitem)
	flying_items.clear()
	emit_signal("inventory_changed")


func remove_item(item_name: String) -> void:
	var i = items.find(item_name)
	if i >= 0:
		items.remove(i)
		emit_signal("inventory_changed")


func item_info(item_name: String) -> Dictionary:
	if item_name in _items_data:
		return _items_data[item_name]
	return {}


func _ready():
	pass
