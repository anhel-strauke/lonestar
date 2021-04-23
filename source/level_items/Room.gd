extends Node2D
class_name Room, "res://editor_assets/icons/room.png"

enum State {INTERACTIVE, ANIMATION}

var _state: int = State.INTERACTIVE
var _waypoints: Array = []
var _objects: Array = []
var _is_points_collected: bool = false
var _character_path = CharacterPath.new()

var _Character = load("res://character/Character.tscn")

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


func remove_point(point: Waypoint):
	var i = _waypoints.find(point)
	if i >= 0:
		_waypoints.remove(i)
		if _waypoints.size() > 1:
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
	for obj in _objects:
		if obj is CharacterSpawn:
			var wp: Waypoint = (obj as CharacterSpawn).get_waypoint_object()
			if wp:
				_character.global_position = wp.global_position
				_character.scale = wp.scale
				_character.direction = Character.Direction.LEFT
				break
	_character.connect("target_reached", self, "_on_character_reached")


func _ready() -> void:
	call_deferred("start_level")


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.INTERACTIVE:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.is_pressed():
			var pos = get_global_mouse_position()
			var path = _character_path.get_waypoints(_character.global_position, _character.scale, pos.x)
			if len(path) > 1:
				print("Moving character to ", pos.x)
				_character.walk_by_path(path)


func is_known_point(point: Waypoint) -> bool:
	return _waypoints.has(point)


func is_known_object(obj: RoomObject) -> bool:
	return _objects.has(obj)


func _on_waypoint_enabled(enabled: bool, wp: Waypoint) -> void:
	pass


func _on_waypoint_excluded(excluded: bool, wp: Waypoint) -> void:
	if _waypoints.has(wp):
		_character_path.update_points(_waypoints)


func _on_character_reached(obj: String) -> void:
	pass

