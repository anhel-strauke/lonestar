tool
extends Node2D
class_name Waypoint, "res://editor_assets/icons/waypoint.png"

export var enabled: bool = true setget set_enabled
var exclude: bool = false setget set_exclude

export var show_character: bool = false setget set_show_character
export var mirror_character: bool = false setget set_mirror_character


signal enabled_changed(enabled)
signal exclude_changed(exclude)


func _ready():
	if not Engine.editor_hint:
		$Character.queue_free()
		$Marker.queue_free()


func set_show_character(show: bool) -> void:
	show_character = show
	if Engine.editor_hint:
		var character = find_node("Character")
		if character:
			character.visible = show


func set_mirror_character(mirror: bool) -> void:
	mirror_character = mirror
	if Engine.editor_hint:
		var character = find_node("Character")
		if character:
			character.flip_h = mirror


func set_enabled(en: bool) -> void:
	if enabled != en:
		enabled = en
		emit_signal("enabled_changed", enabled)
	if Engine.editor_hint:
		var color = "#00ff00" if enabled else "#a0a0a0"
		$Marker.color = color
		$Character.modulate = color


func set_exclude(ex: bool) -> void:
	if exclude != ex:
		exclude = ex
		emit_signal("exclude_changed", exclude)
	
