extends Node2D

enum Direction {LEFT, RIGHT}

var direction: int = Direction.LEFT
var is_walking: bool = false

onready var anim_player = $AnimationPlayer

func _ready():
	_update_animation()


func _update_animation():
	var anim = ""
	if direction == Direction.RIGHT:
		if is_walking:
			anim = "walk_right"
		else:
			anim = "idle_right"
	else:
		if is_walking:
			anim = "walk_left"
		else:
			anim = "idle_left"
	if anim_player.current_animation != anim:
		anim_player.play(anim)
