extends Node2D


onready var _item = $Item
onready var _tween = $Tween

const TARGET_SCALE: float = 0.37
const TIME = 1.0

signal completed()

var _curve = Curve2D.new()

func _ready():
	_tween.connect("tween_all_completed", self, "_on_tween_completed")


func _set_item_pos_on_curve(offset: float) -> void:
	var pos = _curve.interpolate_baked(offset)
	_item.global_position = pos


func animate(point_from: Vector2, point_to: Vector2, icon_index: int) -> void:
	if _tween.is_active():
		_tween.stop_all()
	_tween.remove_all()
	_curve.clear_points()
	if point_from.x <= point_to.x:
		_curve.add_point(point_from, Vector2.ZERO, Vector2(380.0, -380.0))
		_curve.add_point(point_to, Vector2(170.0, -170.0))
	else:
		_curve.add_point(point_from, Vector2.ZERO, Vector2(-380.0, -380.0))
		_curve.add_point(point_to, Vector2(-170.0, -170.0))
	
	_item.visible = true
	_item.frame = icon_index
	_tween.interpolate_method(self, "_set_item_pos_on_curve", 0.0, _curve.get_baked_length(), TIME)
	_tween.interpolate_property(_item, "scale:x", 1.0, TARGET_SCALE, TIME)
	_tween.interpolate_property(_item, "scale:y", 1.0, TARGET_SCALE, TIME)
	_tween.start()


func _on_tween_completed():
	_item.visible = false
	emit_signal("completed")
