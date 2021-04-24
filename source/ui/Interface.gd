extends Node2D

enum State {
	Hidden,
	Showing,
	Visible,
	Hiding
}


signal fade_out_ended()
signal fade_in_ended()


var _state: int = State.Hidden
onready var _anim_player = $InterfaceAnimation
onready var _fader = $Fader

var _inventory_buttons: Array = []


func _ready() -> void:
	_anim_player.connect("animation_finished", self, "_on_animation_finished")
	var inv_button_name_pattern = "BottomPanel/UIRoot/InventoryButton"
	for i in range(6):
		var button_name = inv_button_name_pattern + String(i + 1)
		var object = get_node(button_name)
		if object and object is BaseButton:
			var button: BaseButton = object as BaseButton
			_inventory_buttons.append(button)
			button.readable_item_name = ""
			button.disabled = true
	_fader.connect("shown", self, "_on_fader_shown")
	_fader.connect("hidden", self, "_on_fader_hidden")


func _set_state(new_state: int) -> void:
	if new_state == _state:
		return
	match _state:
		State.Hidden:
			if new_state == State.Showing:
				_anim_player.play("show")
			elif new_state == State.Visible:
				_anim_player.play("show")
				_anim_player.seek(_anim_player.current_animation_length, true)
				_anim_player.stop(false)
		State.Showing:
			if new_state == State.Hiding:
				_anim_player.stop(false)
				_anim_player.play_backwards("show")
			elif new_state == State.Visible:
				_anim_player.seek(_anim_player.current_animation_length, true)
				_anim_player.stop(false)
			elif new_state == State.Hidden:
				_anim_player.stop()
		State.Visible:
			if new_state == State.Hiding:
				_anim_player.play_backwards("show")
			elif new_state == State.Hidden:
				_anim_player.play("show")
				_anim_player.seek(0, true)
				_anim_player.stop()
		State.Hiding:
			if new_state == State.Showing:
				_anim_player.stop(false)
				_anim_player.play("show")
			elif new_state == State.Hidden:
				_anim_player.stop()
			elif new_state == State.Visible:
				_anim_player.stop()
				_anim_player.play("show")
				_anim_player.seek(_anim_player.current_animation_length, true)
				_anim_player.stop(false)
	_state = new_state


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "show":
		match _state:
			State.Showing:
				_state = State.Visible
			State.Hiding:
				_state = State.Hidden


func _on_fader_shown() -> void:
	emit_signal("fade_out_ended")


func _on_fader_hidden() -> void:
	emit_signal("fade_in_ended")


################################################################################
##   API
################################################################################

func show_panels(immediately: bool = false) -> void:
	if immediately:
		_set_state(State.Visible)
	else:
		_set_state(State.Showing)


func hide_panels(immediately: bool = false) -> void:
	if immediately:
		_set_state(State.Hidden)
	else:
		_set_state(State.Hiding)


func screen_fade_out() -> void:
	_fader.show()


func screen_fade_in() -> void:
	_fader.hide()
