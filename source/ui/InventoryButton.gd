extends TextureButton

export var readable_item_name: String setget set_readable_item_name

onready var hint_label = $HintLabel

func set_readable_item_name(new_name: String) -> void:
	readable_item_name = new_name
	call_deferred("_update_hint_label")


func _update_hint_label() -> void:
	if hint_label:
		if readable_item_name:
			hint_label.text = readable_item_name
		else:
			hint_label.text = "(empty)"
		var label_size = hint_label.get_minimum_size()
		var xpos = int((rect_size.x - label_size.x) / 2)
		hint_label.rect_position = Vector2(xpos, -29)


func _ready():
	connect("mouse_entered", self, "_on_mouse_enter")
	connect("mouse_exited", self, "_on_mouse_exit")
	hint_label.visible = false


func _on_mouse_enter():
	if hint_label:
		hint_label.visible = true


func _on_mouse_exit():
	if hint_label:
		hint_label.visible = false
