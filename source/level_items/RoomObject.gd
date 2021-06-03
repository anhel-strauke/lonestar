tool
extends Area2D
class_name RoomObject, "res://editor_assets/icons/room_object.png"

export var waypoint: NodePath = "" setget set_waypoint
export var enabled: bool = true

var _need_update_waypoint: bool = false
var _waypoint_obj: Waypoint = null

var _mouse_over: bool = false
var _room = null


signal activated(with_item)


func set_waypoint(wp: NodePath) -> void:
	waypoint = wp
	_waypoint_obj = null
	if Engine.editor_hint:
		_need_update_waypoint = true
	else:
		var wp_obj = get_node(wp)
		if wp_obj:
			if wp_obj is Waypoint:
				_waypoint_obj = wp_obj


func _update_waypoint() -> void:
	if waypoint and not _waypoint_obj:
		set_waypoint(waypoint)


func _ready() -> void:
	connect("mouse_entered", self, "_set_mouse_over", [true])
	connect("mouse_exited", self, "_set_mouse_over", [false])
	if owner:
		owner.connect("ready", self, "_update_waypoint")


func _process(_delta: float) -> void:
	if Engine.editor_hint:
		if _need_update_waypoint:
			_need_update_waypoint = false
			var wp_obj = get_node(waypoint)
			if wp_obj:
				if wp_obj is Waypoint:
					_waypoint_obj = wp_obj
					update_configuration_warning()


func get_waypoint_object() -> Waypoint:
	return _waypoint_obj


func _get_configuration_warning() -> String:
	var messages = []
	if not waypoint:
		messages.append("Waypoint not set!")
	elif not _waypoint_obj:
		messages.append("Waypoint should be a Waypoint object!")
	if messages:
		var msg = ""
		for m in messages:
			msg += m + "\n"
		msg = msg.trim_suffix("\n")
		return msg
	return ""


func _set_mouse_over(over: bool) -> void:
	_mouse_over = over


func is_mouse_over() -> bool:
	return _mouse_over


func is_this_target(target_name: String) -> bool:
	return name == target_name


func activate(_target_name: String, inventory_item: String) -> void:
	emit_signal("activated", inventory_item)


func deactivate() -> void:
	pass


func set_room(room) -> void:
	_room = room
