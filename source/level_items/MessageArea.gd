extends RoomObject
class_name MessageArea, "res://editor_assets/icons/message_area.png"


export (String, MULTILINE) var dialogue: String = ""
export (int, "Nobody", "Hero") var who_speaks: int = 0


func is_this_target(target_name: String) -> bool:
	return target_name == name


func activate(target_name: String, inventory_item: String) -> void:
	if target_name == name:
		if inventory_item:
			_room.display_wrong_item_message()
		else:
			_room.show_dialogue(dialogue, who_speaks)
