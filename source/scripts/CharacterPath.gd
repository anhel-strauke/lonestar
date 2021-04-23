extends Reference
class_name CharacterPath

var _points: Array = []
var _x_min: float = 0.0
var _x_max: float = 0.0


class PointsXSorter:
	static func sort_asc(a: Waypoint, b: Waypoint) -> bool:
		return a.global_position.x < b.global_position.x


func update_points(new_points: Array) -> void:
	assert(len(new_points) > 1)
	var sorted_points := []
	for point in new_points:
		if not point.exclude:
			sorted_points.append(point)
	sorted_points.sort_custom(PointsXSorter, "sort_asc")
	_points = sorted_points
	assert(len(_points) > 1)
	_x_min = _points[0].global_position.x
	_x_max = _points[-1].global_position.x


func exclude_waypoint(point: Waypoint) -> void:
	var i = _points.find(point)
	if i >= 0:
		_points.remove(i)


func _interpolate(point_a: Waypoint, point_b: Waypoint, x: float) -> Dictionary:
	if point_a.global_position.x == point_b.global_position.x:
		return {
			position = point_b.position,
			scale = point_b.scale
		}
	var amount = (x - point_a.global_position.x) / (point_b.global_position.x - point_a.global_position.x)
	var y = (point_b.global_position.y - point_a.global_position.y) * amount + point_a.global_position.y
	var scale_x = (point_b.scale.x - point_a.scale.x) * amount + point_a.scale.x
	var scale_y = (point_b.scale.y - point_a.scale.y) * amount + point_a.scale.y
	var result = {
		position = Vector2(x, y),
		scale = Vector2(scale_x, scale_y)
	}
	return result


func _dict_from_waypoint(w: Waypoint) -> Dictionary:
	return {
		position = w.global_position,
		scale = w.scale
	}


func get_point_for(x: float) -> Dictionary:
	assert(len(_points) > 1)
	if x < _x_min:
		x = _x_min
	elif x > _x_max:
		x = _x_max
	for i in range(len(_points) - 1):
		var point_a = _points[i]
		var point_b = _points[i + 1]
		if point_a.x == point_b.x:
			continue
		if (point_a.x <= x) and (x <= point_b.x):
			return _interpolate(point_a, point_b, x)
	return _dict_from_waypoint(_points[-1])


func _get_segment_index(x: float) -> int:
	assert(len(_points) > 1)
	if x < _x_min:
		return -1
	elif x > _x_max:
		return len(_points) - 1
	for i in range(len(_points) - 1):
		var point_a = _points[i]
		var point_b = _points[i + 1]
		if (point_a.global_position.x <= x) and (x <= point_b.global_position.x):
			return i
	return len(_points) - 1


func _get_last_reachable_segment(from_index: int, to_index: int) -> int:
	if from_index < to_index:
		for i in range(from_index + 1, to_index + 1):
			var curr_point: Waypoint = _points[i]
			if not curr_point.enabled:
				return i - 1
			elif i == to_index:
				return i
	elif from_index > to_index:
		for i in range(from_index, to_index, -1):
			var curr_point: Waypoint = _points[i]
			if not curr_point.enabled:
				return i
			elif i == to_index + 1:
				return to_index
	return to_index


func _interpolate_segment(segment_index: int, x: float) -> Dictionary:
	if segment_index < 0:
		return {position = Vector2(x, _points[0].global_position.y), scale = _points[0].scale}
	elif segment_index >= len(_points) - 1:
		return {position = Vector2(x, _points[-1].global_position.y), scale = _points[-1].scale}
	else:
		return _interpolate(_points[segment_index], _points[segment_index + 1], x)


# Returns array of dictionaries {position, scale}. If target x position is
# unreachable, last dictionary in the array will have additional key "broken": true.
func get_waypoints(from: Vector2, from_scale: Vector2, to_x: float) -> Array:
	assert(len(_points) > 1)
	to_x = clamp(to_x, _x_min, _x_max)
	if to_x == from.x:
		return []
	var result: Array = [{position = from, scale = from_scale}]
	var from_index := _get_segment_index(from.x)
	var target_index := _get_segment_index(to_x)
	var to_index := _get_last_reachable_segment(from_index, target_index)
	if from_index == to_index:
		result.append(_interpolate_segment(to_index, to_x))
	elif from_index < to_index: 
		for i in range(from_index + 1, to_index + 1):
			result.append({position = _points[i].global_position, scale = _points[i].scale})
	else:
		for i in range(from_index, to_index, -1):
			result.append({position = _points[i].global_position, scale = _points[i].scale})
	if result[-1].position.x != to_x:
		result.append(_interpolate_segment(to_index, to_x))
	if to_index != target_index:
		result[-1].broken = true
	return result
