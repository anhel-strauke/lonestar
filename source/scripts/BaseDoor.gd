tool
extends RoomObject
class_name BaseDoor

enum DoorState {
	Closed,
	Opening,
	Open,
	Closing
}

export var animation_player: NodePath = "" setget set_animation_player
var _anim_player: AnimationPlayer = null
var _need_update_anim_player: bool = false
export var waypoint_behind_door: NodePath = "" setget set_target_waypoint
var _target_waypoint_obj: Waypoint = null
var _need_update_target_waypoint: bool = false

export var target_room: String = ""

var _state: int = DoorState.Closed


func _update_waypoint() -> void:
	._update_waypoint()
	if waypoint_behind_door and not _target_waypoint_obj:
		set_target_waypoint(waypoint_behind_door)
	if animation_player and not _anim_player:
		set_animation_player(animation_player)


func set_target_waypoint(wp_path: NodePath) -> void:
	waypoint_behind_door = wp_path
	if _target_waypoint_obj:
		_target_waypoint_obj.exclude = false
	_target_waypoint_obj = null
	if Engine.editor_hint:
		_need_update_target_waypoint = true
	else:
		var wp_obj = get_node(wp_path)
		if wp_obj:
			if wp_obj is Waypoint:
				_target_waypoint_obj = wp_obj
				_target_waypoint_obj.exclude = true


func get_target_waypoint_object() -> Waypoint:
	return _target_waypoint_obj


func open_immediately() -> void:
	_set_state(DoorState.Open)


func set_animation_player(ap_path: NodePath) -> void:
	animation_player = ap_path
	if _anim_player:
		_anim_player.disconnect("animation_finished", self, "_on_animation_finished")
	_anim_player = null
	if Engine.editor_hint:
		_need_update_anim_player = true
	else:
		var ap_obj = get_node(ap_path)
		if ap_obj:
			if ap_obj is AnimationPlayer:
				_anim_player = ap_obj
				_anim_player.connect("animation_finished", self, "_on_animation_finished")


func _process(_delta: float) -> void:
	if Engine.editor_hint:
		if _need_update_target_waypoint:
			_need_update_target_waypoint = false
			var wp_obj = get_node(waypoint_behind_door)
			if wp_obj:
				if wp_obj is Waypoint:
					_target_waypoint_obj = wp_obj
					_target_waypoint_obj.exclude = true
					update_configuration_warning()
		if _need_update_anim_player:
			_need_update_anim_player = false
			var ap_obj = get_node(animation_player)
			if ap_obj:
				if ap_obj is AnimationPlayer and _anim_player != ap_obj:
					_anim_player = ap_obj
					_anim_player.connect("animation_finished", self, "_on_animation_finished")
					update_configuration_warning()


func _get_configuration_warning() -> String:
	var base_msg = ._get_configuration_warning()
	var messages = []
	if not waypoint_behind_door:
		messages.append("Waypoint behind the door not set!")
	elif not _target_waypoint_obj:
		messages.append("Waypoint behind the door should be a Waypoint object!")
	if not animation_player:
		messages.append("Door animation player is not set!")
	elif not _anim_player:
		messages.append("Door animation player must be an AnimationPlayer object!")
	if messages:
		var msg = base_msg + "\n"
		for m in messages:
			msg += m + "\n"
		msg = msg.trim_suffix("\n")
		return msg
	return base_msg


func _set_state(new_state: int) -> void:
	if new_state == _state:
		return
	match _state:
		DoorState.Closed:
			if new_state == DoorState.Opening:
				_anim_player.play("open")
			elif new_state == DoorState.Open:
				_anim_player.play("open")
				_anim_player.seek(_anim_player.current_animation_length, true)
		DoorState.Open:
			if new_state == DoorState.Closing:
				_anim_player.play_backwards("open")
			elif new_state == DoorState.Closed:
				_anim_player.play("open")
				_anim_player.seek(0, true)
				_anim_player.stop()
		DoorState.Opening:
			if new_state == DoorState.Closing:
				_anim_player.stop(false)
				_anim_player.play_backwards("open")
			elif new_state == DoorState.Open:
				_anim_player.seek(_anim_player.current_animation_length, true)
			elif new_state == DoorState.Closed:
				_anim_player.stop()
		DoorState.Closing:
			if new_state == DoorState.Opening:
				_anim_player.stop(false)
				_anim_player.play("open")
			elif new_state == DoorState.Closed:
				_anim_player.stop()
			elif new_state == DoorState.Open:
				_anim_player.stop()
				_anim_player.play("open")
				_anim_player.seek(_anim_player.current_animation_length)
	_state = new_state


func _on_animation_finished(anim_name):
	if anim_name != "open":
		return
	match _state:
		DoorState.Opening:
			print("Open!")
			_set_state(DoorState.Open)
			_room.set_interactive_mode(false)
			_room.move_character_to(_target_waypoint_obj.global_position, _target_waypoint_obj.scale, name + "__target_wp")
		DoorState.Closing:
			_set_state(DoorState.Closed)


func is_this_target(target_name: String) -> bool:
	return (
		name == target_name or 
		name + "__target_wp" == target_name or 
		name + "__src_wp" == target_name or
		name + "__start_level" == target_name
	)


func activate(target_name: String, inventory_item: String) -> void:
	if inventory_item:
		_room.display_wrong_item_message()
		return
	if not target_room:
		_room.show_dialogue("This door is closed.", 1)
		return
	if target_name == name:
		_room.character_look_at(_target_waypoint_obj.global_position.x)
		_set_state(DoorState.Opening)
	elif target_name == name + "__target_wp":
		_room.go_to_room(target_room)
	elif target_name == name + "__src_wp" or target_name == name + "__start_level":
		_set_state(DoorState.Closing)
		_room.set_interactive_mode(true)


func deactivate() -> void:
	_set_state(DoorState.Closing)
