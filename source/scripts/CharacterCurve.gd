extends Reference
class_name CharacterCurve

class ScaledCurve:
	var _x_min: float = 0.0
	var _x_max: float = 1.0
	var _points: Array = []
	var _curve: Curve = Curve.new()
	var _baked = false
	func add_point(p: Vector2) -> void:
		_x_min = min(p.x, _x_min)
		_x_max = max(p.x, _x_max)
		_points.append(p)
		_baked = false
	func clear_points() -> void:
		_points.clear()
		_curve.clear_points()
		_baked = false
	func interpolate_baked(x: float) -> float:
		if not _baked:
			for p in _points:
				var curve_x = (p.x - _x_min) / (_x_max - _x_min)
				_curve.add_point(Vector2(curve_x, p.y))
			_baked = true
		return _curve.interpolate_baked((x - _x_min) / (_x_max - _x_min))


var y_curve: Curve2D = Curve2D.new()
var scale_x_curve: ScaledCurve = ScaledCurve.new()
var scale_y_curve: ScaledCurve = ScaledCurve.new()


func add_point(x: float, y: float, scale_x: float = 1.0, scale_y: float = 1.0) -> void:
	y_curve.add_point(Vector2(x, y))
	scale_x_curve.add_point(Vector2(x, scale_x))
	scale_y_curve.add_point(Vector2(x, scale_y))

func clear_points() -> void:
	y_curve.clear_points()
	scale_x_curve.clear_points()
	scale_y_curve.clear_points()

func interpolate_position(dist: float) -> Vector2:
	return y_curve.interpolate_baked(dist)

func interpolate_scale(x: float) -> Vector2:
	var scale_x := scale_x_curve.interpolate_baked(x)
	var scale_y := scale_y_curve.interpolate_baked(x)
	return Vector2(scale_x, scale_y)

func get_point_count() -> int:
	return y_curve.get_point_count()

func get_baked_length() -> float:
	return y_curve.get_baked_length()
