extends Node2D

# Dialogues syntax
# * Phrases are separated by a single . on a line
# * Character portrait can be set with .X on the separate line (X is character index)
# * Line breaks are preserved
# Example:
# This phrase is said by the default character
# Second line of the first phrase.
# .
# Another phrase said by the default character
# .1
# This is third phrase and it will display character portrait #1 instaed of the default one.

enum State {
	Hidden,
	Showing,
	AnimatingText,
	Idle,
	Hiding
}

onready var _show_anim = $ShowHidePlayer
onready var _text_tween = $TextAnimationTween
onready var _text_label = $MovingParent/DialogueBox/Label
onready var _portrait = $MovingParent/DialogueBox/Portrait

var _state: int = State.Hidden
var _dialogue_queue: Array = []

const CPS: float = 20.0; # Number of characters per second

signal dialog_started()
signal dialog_finished()
signal dialog_signal(signal_name)


func show_dialog_text(text: String, default_who: int = 0) -> void:
	var phrases = _parse_dialog_text(text, default_who)
	_dialogue_queue.append_array(phrases)
	if len(_dialogue_queue) == 0:
		return
	if _state == State.Hidden or _state == State.Hiding:
		_reset_window(_dialogue_queue[0].who)
		_set_state(State.Showing)
		emit_signal("dialog_started")


func show_dialog_directly(replicas: Array) -> void:
	_dialogue_queue.append_array(replicas)
	if _state == State.Hidden or _state == State.Hiding:
		_set_state(State.Showing)
		_reset_window(_dialogue_queue[0].who)
		emit_signal("dialog_started")


func hide_dialog() -> void:
	_set_state(State.Hiding)


func _ready() -> void:
	_show_anim.connect("animation_finished", self, "_on_show_animation_end")
	_text_tween.connect("tween_completed", self, "_on_text_tween_end")
	_text_label.text = ""


func _input(event: InputEvent) -> void:
	if _state == State.Idle:
		if _is_skip_input_event(event):
			get_tree().set_input_as_handled()
			_show_next_replica()
	elif _state == State.AnimatingText:
		if _is_skip_input_event(event):
			_set_state(State.Idle)
			get_tree().set_input_as_handled()


func _is_skip_input_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return not event.is_pressed() and event.button_index == BUTTON_LEFT
	elif event is InputEventAction:
		return not event.is_pressed() and (event.action == "ui_accept" or event.action == "ui_cancel")
	return false


func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	match _state:
		State.Hidden:
			if new_state == State.Showing:
				_show_anim.play("show")
			elif new_state == State.Hiding:
				return
			elif new_state != State.Hiding:
				printerr("Dialogue: illegal state change")
				return
		State.Showing:
			if new_state == State.Hiding:
				_show_anim.stop(false)
				_show_anim.play_backwards("show")
			elif new_state == State.Hidden:
				_show_anim.stop()
			elif new_state == State.AnimatingText:
				_animate_label_text()
			else:
				printerr("Dialogue: illegal state change")
				return
		State.AnimatingText:
			if new_state == State.Idle:
				_text_tween.seek(_text_tween.get_runtime())
			elif new_state == State.Hiding:
				_text_tween.stop_all()
				_show_anim.play_backwards("show")
			elif new_state == State.Hidden:
				_text_tween.stop_all()
				_show_anim.play("show")
				_show_anim.seek(0, true)
				_show_anim.stop()
			else:
				printerr("Dialogue: illegal state change")
				return
		State.Idle:
			if new_state == State.AnimatingText:
				_animate_label_text()
			elif new_state == State.Hiding:
				_show_anim.play_backwards("show")
			elif new_state == State.Hidden:
				_show_anim.play("show")
				_show_anim.seek(0, true)
				_show_anim.stop()
			else:
				printerr("Dialogue: illegal state change")
				return
		State.Hiding:
			if new_state == State.Showing:
				_show_anim.stop(false)
				_show_anim.play("show")
			elif new_state == State.Hidden:
				_show_anim.stop()
			else:
				printerr("Dialogue: illegal state change")
				return
	_state = new_state


func _animate_label_text() -> void:
	var text = _text_label.text
	var t := len(text) / CPS;
	_text_tween.remove_all()
	_text_tween.interpolate_property(_text_label, "visible_characters", 0, len(text), t, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_text_tween.start()


func _on_show_animation_end(anim_name: String) -> void:
	if anim_name == "show":
		match _state:
			State.Showing:
				_show_next_replica()
			State.Hiding:
				_state = State.Hidden


func _on_text_tween_end(_label: Object, _key: NodePath) -> void:
	_state = State.Idle


func _show_next_replica() -> void:
	if len(_dialogue_queue) > 0:
		var next_replica = _dialogue_queue.pop_front()
		if "send_signal" in next_replica:
			emit_signal("dialog_signal", next_replica.send_signal)
			call_deferred("_show_next_replica")
		else:
			_portrait.frame = next_replica.who
			_text_label.text = next_replica.what
			_text_label.visible_characters = 0
			_set_state(State.AnimatingText)
	else:
		_set_state(State.Hiding)
		emit_signal("dialog_finished")


func _reset_window(who: int = 0) -> void:
	_text_label.text = ""
	_portrait.frame = who


# Result is an array of dicts {"who": character_index, "what": phrase_to_say}
func _parse_dialog_text(text: String, default_who: int = 0) -> Array:
	var result := []
	var lines := text.split("\n")
	var current_who = default_who
	var current_replica = ""
	for line in lines:
		if line.begins_with("."):
			var stripped_line = line.strip_edges()
			if stripped_line == ".":
				if current_replica.strip_edges() != "":
					result.append({who = current_who, what = current_replica})
				current_replica = ""
				continue
			else:
				var who_index_str = stripped_line.substr(1)
				var signal_prefix = "signal "
				if who_index_str.begins_with(signal_prefix):
					who_index_str = who_index_str.trim_prefix(signal_prefix).strip_edges()
					if current_replica.strip_edges() != "":
						result.append({who = current_who, what = current_replica})
					current_replica = ""
					result.append({send_signal = who_index_str})
					continue
				elif who_index_str.is_valid_integer():
					if current_replica.strip_edges() != "":
						result.append({who = current_who, what = current_replica})
					current_replica = ""
					current_who = who_index_str.to_int()
					continue
		if current_replica.length() > 0:
			current_replica += "\n"
		current_replica += line
	if current_replica.strip_edges() != "":
		result.append({who = current_who, what = current_replica})
	return result
