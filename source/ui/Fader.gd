extends Node2D

signal shown()
signal hidden()


onready var _anim_player: AnimationPlayer = $AnimationPlayer


func _ready():
	_anim_player.connect("animation_finished", self, "_on_animation_stopped")


func _on_animation_stopped(anim: String) -> void:
	if anim == "show":
		emit_signal("shown")
	elif anim == "hide":
		emit_signal("hidden")


func show():
	_anim_player.play("show")


func hide():
	_anim_player.play("hide")
