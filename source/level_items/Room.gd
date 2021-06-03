extends Node2D
class_name Room, "res://editor_assets/icons/room.png"

enum State {INTERACTIVE, ANIMATION}

export var default_character_waypoint: NodePath = ""

signal dialog_signal(signal_name)

var _state: int = State.INTERACTIVE
var _waypoints: Array = []
var _objects: Array = []
var _is_points_collected: bool = false
var _character_path = CharacterPath.new()
var _level_started: bool = false

const _Character = preload("res://character/Character.tscn")

var _character: Character = null


func add_point(point: Waypoint) -> void:
	if is_known_point(point):
		return
	_waypoints.append(point)
	point.connect("enabled_changed", self, "_on_waypoint_enabled", [point])
	point.connect("exclude_changed", self, "_on_waypoint_excluded", [point])
	point.connect("tree_exited", self, "remove_point", [point])


func add_object(obj: RoomObject) -> void:
	if is_known_object(obj):
		return
	_objects.append(obj)
	obj.set_room(self)


func objects_under_mouse() -> Array:
	var result = []
	for obj in _objects:
		if obj.is_mouse_over():
			result.append(obj)
	return result


func remove_point(point: Waypoint):
	var i = _waypoints.find(point)
	if i >= 0:
		_waypoints.remove(i)
		var c = 0
		for wp in _waypoints:
			if not wp.exclude:
				c += 1
		if c > 1:
			_character_path.update_points(_waypoints)


func _collect_objects(root: Node) -> void:
	var children_count = root.get_child_count()
	if children_count == 0:
		return
	for i in range(children_count):
		var child = root.get_child(i)
		if child is Waypoint:
			add_point(child)
		elif child is RoomObject:
			add_object(child)
		_collect_objects(child)


func _collect_objects_from_root() -> void:
	if _is_points_collected:
		return
	_collect_objects(self)
	if len(_waypoints) >= 2:
		_character_path.update_points(_waypoints)
	_is_points_collected = true


func start_level() -> void:
	_collect_objects_from_root()
	assert(_is_points_collected)
	var parent = get_parent()
	_character = _Character.instance()
	parent.add_child(_character)
	_character.connect("target_reached", self, "_on_character_reached")
	set_interactive_mode(false)
	Interface.connect("fade_in_ended", self, "_begin_gameplay", [], CONNECT_ONESHOT + CONNECT_DEFERRED)
	Interface.screen_fade_in()
	Interface.connect("dialog_signal", self, "_on_dialog_signal")
	_level_started = true
	if Game.get_come_from_room_name():
		if put_character_to_door_from(Game.get_come_from_room_name()):
			return
	if default_character_waypoint:
		var default_wp = get_node(default_character_waypoint)
		if default_wp and default_wp is Waypoint:
			_character.global_position = default_wp.global_position
			_character.scale = default_wp.scale
			if default_wp.mirror_character:
				_character.set_direction(Character.Direction.LEFT)
			else:
				_character.set_direction(Character.Direction.RIGHT)
			return
	_character.scale = Vector2.ONE
	_character.global_position = Vector2(1280 / 2, 600)


func _begin_gameplay() -> void:
	Interface.show_panels()
	set_interactive_mode(true)


func _ready() -> void:
	call_deferred("start_level")


func _on_dialog_signal(signal_name: String) -> void:
	emit_signal("dialog_signal", signal_name)


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.INTERACTIVE or not _level_started:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.is_pressed():
			var mouse_objects = objects_under_mouse()
			if mouse_objects:
				var obj = mouse_objects[0]
				if obj.enabled:
					var wp = obj.get_waypoint_object()
					var path = _character_path.get_waypoints(_character.global_position, _character.scale, wp.global_position.x)
					if len(path) > 1:
						print("Moving character to ", obj.name)
						_deactivate_objects()
						var item_name = Interface.selected_inventory_item()
						_character.walk_by_path_to_target(path, obj.name, item_name)
						Interface.set_inventory_cursor("")
						Interface.set_selected_inventory_item(item_name)
					else:
						var item_name = Interface.selected_inventory_item()
						_deactivate_objects()
						Interface.set_inventory_cursor("")
						_activate_object(obj.name, item_name)
					return
			var pos = get_global_mouse_position()
			var path = _character_path.get_waypoints(_character.global_position, _character.scale, pos.x)
			if len(path) > 1:
				print("Moving character to ", pos.x)
				_deactivate_objects()
				_character.walk_by_path(path)
				Interface.deselect_inventory_item()
				Interface.set_inventory_cursor("")


func is_known_point(point: Waypoint) -> bool:
	return _waypoints.has(point)


func is_known_object(obj: RoomObject) -> bool:
	return _objects.has(obj)


func _on_waypoint_enabled(enabled: bool, wp: Waypoint) -> void:
	pass


func _on_waypoint_excluded(excluded: bool, wp: Waypoint) -> void:
	if _waypoints.has(wp):
		_character_path.update_points(_waypoints)


func _on_character_reached(reached_obj_name: String, inventory_item: String) -> void:
	print("Character reached " + reached_obj_name)
	_activate_object(reached_obj_name, inventory_item)


func _deactivate_objects() -> void:
	for obj in _objects:
		obj.deactivate()


func _activate_object(target_name: String, inventory_item: String) -> void:
	for obj in _objects:
		if obj.is_this_target(target_name):
			obj.activate(target_name, inventory_item)
			break
	Interface.deselect_inventory_item()


func set_interactive_mode(is_interactive: bool) -> void:
	if is_interactive:
		_state = State.INTERACTIVE
	else:
		_state = State.ANIMATION


func move_character_to(target_pos: Vector2, target_scale: Vector2, target_name: String, target_item: String = "") -> void:
	var path = [
		{
			position = _character.global_position,
			scale = _character.scale
		},
		{
			position = target_pos,
			scale = target_scale
		}
	]
	_character.walk_by_path_to_target(path, target_name, target_item)


func character_look_at(target_x: float) -> void:
	_character.update_character_direction(target_x)


func put_character_to_door_from(room_name: String) -> bool:
	for obj in _objects:
		if obj is BaseDoor:
			var door = obj as BaseDoor
			if door.target_room == room_name:
				door.open_immediately()
				var wp_start: Waypoint = door.get_target_waypoint_object()
				var wp_end: Waypoint = door.get_waypoint_object()
				if wp_start and wp_end:
					_character.global_position = wp_start.global_position
					_character.scale = wp_start.scale
					move_character_to(wp_end.global_position, wp_end.scale, door.name + "__start_level")
					return true
				else:
					printerr("CRITICAL: Bad waypoints at door \"" + door.name + "\"")
					return false
	return false


func go_to_room(room_name: String) -> void:
	set_interactive_mode(false)
	Game.go_to_room(room_name)


func show_dialogue(text: String, default_who: int = 0) -> void:
	Interface.show_dialogue_text(text, default_who)


func show_dialogue_dict(replicas: Array) -> void:
	Interface.show_dialogue_directly(replicas)


func selected_inventory_item() -> String:
	return Interface.selected_inventory_item()


func display_wrong_item_message() -> void:
	var messages = [
		"What am I trying to do with this?", 
		"I don't think this will work.", 
		"Nothing happens."
	]
	var msg = messages[randi() % len(messages)]
	Interface.show_dialogue_text(msg, 1)
