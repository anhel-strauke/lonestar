extends Node

var _come_from_room: String = ""
var _next_room: String = ""

const FaderScene = preload("res://ui/Fader.tscn")


func _ready():
	pass


func get_come_from_room_name() -> String:
	return _come_from_room


func go_to_room(to_room: String) -> void:
	_next_room = to_room
	call_deferred("_deferred_go_to_room")


func _deferred_go_to_room() -> void:
	var current_scene = get_tree().current_scene
	var current_scene_name = _room_scene_name_from_filename(current_scene.filename)
	_come_from_room = current_scene_name
	Interface.connect("fade_out_ended", self, "_continue_go_to_room")
	Interface.screen_fade_out()


func _continue_go_to_room() -> void:
	var new_scene_file = _room_scene_filename(_next_room)
	get_tree().change_scene(new_scene_file)


func find_room_object(scene: Node):
	if scene.get_class() == "Room":
		return scene
	for i in scene.get_child_count():
		var room = find_room_object(scene.get_child(i))
		if room:
			return room
	return null


func _room_scene_filename(room_name: String) -> String:
	return "res://rooms/" + room_name + ".tscn"


func _room_scene_name_from_filename(scene_file_name: String) -> String:
	return scene_file_name.get_basename().get_file()
