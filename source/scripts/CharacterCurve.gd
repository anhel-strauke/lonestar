extends Reference
class_name CharacterCurve

class ScaledCurve:
	var _points: Array = []
	var _curve: Curve = Curve.new()
	var _xycurve: Curve2D = null
	var _baked = false
	func _init(xycurve: Curve2D):
		_xycurve = xycurve
	func add_point(p: Vector2, scale: float) -> void:
		_points.append([p, scale])
		_baked = false
	func clear_points() -> void:
		_points.clear()
		_curve.clear_points()
		_baked = false
	func interpolate_baked(offset: float) -> float:
		var max_offset = _xycurve.get_baked_length()
		if not _baked:
			for p in _points:
				var pos = p[0]
				var scale = p[1]
				var pos_offset = _xycurve.get_closest_offset(pos)
				var curve_x = pos_offset / max_offset
				_curve.add_point(Vector2(curve_x, scale))
			_baked = true
		return _curve.interpolate_baked(offset / max_offset)


var y_curve: Curve2D = Curve2D.new()
var scale_x_curve: ScaledCurve = ScaledCurve.new(y_curve)
var scale_y_curve: ScaledCurve = ScaledCurve.new(y_curve)


func add_point(x: float, y: float, scale_x: float = 1.0, scale_y: float = 1.0) -> void:
	var p := Vector2(x, y)
	y_curve.add_point(p)
	scale_x_curve.add_point(p, scale_x)
	scale_y_curve.add_point(p, scale_y)

func clear_points() -> void:
	y_curve.clear_points()
	scale_x_curve.clear_points()
	scale_y_curve.clear_points()

func interpolate_position(dist: float) -> Vector2:
	return y_curve.interpolate_baked(dist)

func interpolate_scale(dist: float) -> Vector2:
	var scale_x := scale_x_curve.interpolate_baked(dist)
	var scale_y := scale_y_curve.interpolate_baked(dist)
	return Vector2(scale_x, scale_y)

func get_point_count() -> int:
	return y_curve.get_point_count()

func get_baked_length() -> float:
	return y_curve.get_baked_length()
