extends TextureButton

export var _readable_item_name: String = ""
export var item_name: String setget set_item

onready var _hint_label = $HintLabel
onready var _icon = $Icon

signal selected(item_name)

func set_readable_item_name(new_name: String) -> void:
	_readable_item_name = new_name
	call_deferred("_update_hint_label")


func _on_click() -> void:
	emit_signal("selected", item_name)


func set_item(new_item: String) -> void:
	item_name = new_item
	if new_item:
		var info = Game.inventory.item_info(new_item)
		if info:
			_icon.frame = info.icon_index
			set_readable_item_name(info.title)
			disabled = false
			return
		else:
			printerr("ERROR: Inventory button can't find item \"" + new_item + "\"")
			item_name = ""
	disabled = true
	_icon.frame = 0
	set_readable_item_name("")


func _update_hint_label() -> void:
	if _hint_label:
		if _readable_item_name:
			_hint_label.text = _readable_item_name
		else:
			_hint_label.text = "(empty)"
		var label_size = _hint_label.get_minimum_size()
		var xpos = int((rect_size.x - label_size.x) / 2)
		_hint_label.rect_position = Vector2(xpos, -29)


func icon_global_position() -> Vector2:
	return _icon.global_position


func _ready():
	connect("mouse_entered", self, "_on_mouse_enter")
	connect("mouse_exited", self, "_on_mouse_exit")
	connect("pressed", self, "_on_click")
	_hint_label.visible = false


func _on_mouse_enter():
	if _hint_label:
		_hint_label.visible = true


func _on_mouse_exit():
	if _hint_label:
		_hint_label.visible = false
