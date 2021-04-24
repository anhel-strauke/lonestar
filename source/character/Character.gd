extends Node2D
class_name Character

enum Direction {LEFT, RIGHT}
enum State {IDLE, WALKING}

const EPSILON = 0.01

signal target_reached(target) # target: String = name of the target


var direction: int = Direction.LEFT setget set_direction
var _state: int = State.IDLE
var _speed: float = 200.0
var _walking_path := CharacterCurve.new()
var _walking_progress = 0.0
var _target_object: String = ""
var _path_was_broken: bool = false

onready var anim_player = $AnimationPlayer


func _ready() -> void:
	_update_animation()


func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			pass
		State.WALKING:
			if _walking_path.get_point_count() < 2:
				_walking_path.clear_points()
				_state = State.IDLE
				_update_animation()
				return
			var dist = delta * _speed
			var target_point: Vector2 = Vector2.ZERO
			var target_scale: Vector2 = Vector2.ONE
			_walking_progress += dist
			if _walking_progress > _walking_path.get_baked_length():
				target_point = _walking_path.interpolate_position(_walking_path.get_baked_length())
				target_scale = _walking_path.interpolate_scale(_walking_path.get_baked_length())
				_walking_path.clear_points()
				_state = State.IDLE
				if _target_object:
					var target_obj = _target_object
					_target_object = "" # It should be cleared BEFORE signal emitting
					if not _path_was_broken:
						emit_signal("target_reached", target_obj)
				_update_animation()
			else:
				target_point = _walking_path.interpolate_position(_walking_progress)
				target_scale = _walking_path.interpolate_scale(_walking_progress)
			update_character_direction(target_point.x)
			global_position = target_point
			scale = target_scale


func update_character_direction(target_x: float) -> void:
	var new_dir = direction
	if target_x > (global_position.x + EPSILON):
		new_dir = Direction.RIGHT
	elif target_x < (global_position.x - EPSILON):
		new_dir = Direction.LEFT
	if new_dir != direction:
		direction = new_dir
		_update_animation()


func _update_animation() -> void:
	var anim = ""
	if direction == Direction.RIGHT:
		if _state == State.WALKING:
			anim = "walk_right"
		else:
			anim = "idle_right"
	else:
		if _state == State.WALKING:
			anim = "walk_left"
		else:
			anim = "idle_left"
	if anim_player.current_animation != anim:
		anim_player.play(anim)


func walk_by_path(var waypoints: Array) -> void:
	_target_object = ""
	_walking_path.clear_points()
	_path_was_broken = false
	if len(waypoints) > 1:
		_state = State.WALKING
		for point in waypoints:
			_walking_path.add_point(point.position.x, point.position.y, point.scale.x, point.scale.y)
		global_position = _walking_path.interpolate_position(0.0) # Curve is baked on the first access
		scale = _walking_path.interpolate_scale(0.0)
		_walking_progress = 0.0
		_path_was_broken = waypoints[-1].has("broken")
	else:
		if len(waypoints) > 0:
			global_position = waypoints[0].position
			scale = waypoints[0].scale
		_state = State.IDLE
	_update_animation()


func walk_by_path_to_target(var waypoints: Array, target: String):
	print("Character: Walking to " + target)
	walk_by_path(waypoints)
	_target_object = target


func set_direction(dir: int) -> void:
	if direction != dir:
		direction = dir
		_update_animation()
