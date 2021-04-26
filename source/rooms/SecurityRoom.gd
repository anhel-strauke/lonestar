extends Node2D

func _ready():
	pass


func _on_Room_dialog_signal(signal_name):
	match signal_name:
		"give_fuse":
			Game.give_inventory_item("fuse", $Room/TrashMessage/Position.global_position)
