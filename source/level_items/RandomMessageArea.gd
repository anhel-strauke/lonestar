tool
extends RoomObject
class_name RandomMessageArea, "res://editor_assets/icons/random_message_area.png"

export (Array, String, MULTILINE) var messages = []
export (int, "Nobody", "Hero") var who_speaks: int = 0


func is_this_target(target_name: String) -> bool:
	return target_name == name and len(messages) > 0


func activate(target_name: String, inventory_item: String) -> void:
	if target_name == name:
		if inventory_item:
			_room.display_wrong_item_message()
		else:
			var dialog_index := randi() % len(messages)
			_room.show_dialogue(messages[dialog_index], who_speaks)
