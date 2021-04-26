extends Node2D

var selected_item_name: String = "" setget set_selected_item_name

onready var _moving_item = $inventory_items

func _ready():
	pass


func set_selected_item_name(new_name: String) -> void:
	if new_name:
		var info = Game.inventory.item_info(new_name)
		if info:
			_moving_item.frame = info.icon_index
			_moving_item.visible = true
			set_process(true)
	else:
		_moving_item.frame = 0
		_moving_item.visible = false
		set_process(false)
	selected_item_name = new_name


func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	_moving_item.global_position = mouse_pos
