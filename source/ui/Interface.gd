extends Node2D

enum State {
	Hidden,
	Showing,
	Visible,
	Hiding
}


signal fade_out_ended()
signal fade_in_ended()
signal dialog_signal(signal_name)


var _state: int = State.Hidden
onready var _anim_player = $InterfaceAnimation
onready var _fader = $Fader
onready var _dialogue = $Dialogue
onready var _inventory_cursor = $InventoryCursor
onready var _inventory_flying_item_animation = $InventoryItemAnimation
var _inventory_manager = preload("res://ui/InventoryManager.gd").new()

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
			button.set_readable_item_name("")
			button.disabled = true
	_inventory_manager.set_buttons(_inventory_buttons)
	Game.inventory.connect("inventory_changed", _inventory_manager, "update_inventory")
	_fader.visible = true
	_fader.connect("shown", self, "_on_fader_shown")
	_fader.connect("hidden", self, "_on_fader_hidden")
	_dialogue.connect("dialog_signal", self, "_on_dialog_signal")
	_inventory_flying_item_animation.connect("completed", self, "_on_inventory_item_animation_complete")


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


func _on_dialog_signal(signal_name: String) -> void:
	emit_signal("dialog_signal", signal_name)

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
	_dialogue.hide_dialog()
	_fader.show()


func screen_fade_in() -> void:
	_fader.hide()


func show_dialogue_text(dialogue_text: String, default_who: int = 0) -> void:
	_dialogue.show_dialog_text(dialogue_text, default_who)


func show_dialogue_directly(replicas: Array) -> void:
	_dialogue.show_dialog_directly(replicas)


func set_inventory_cursor(item_name: String) -> void:
	_inventory_cursor.set_selected_item_name(item_name)


func reset() -> void:
	set_inventory_cursor("")


func add_flying_inventory_item(item_name: String, from_pos: Vector2) -> void:
	var button = _inventory_manager.find_first_available_button()
	var target_pos = Vector2(1920 / 2, 1080 - 30)
	if button:
		target_pos = button.icon_global_position()
	var info = Game.inventory.item_info(item_name)
	if info:
		_inventory_flying_item_animation.animate(from_pos, target_pos, info.icon_index)


func _on_inventory_item_animation_complete() -> void:
	Game.inventory.merge_flying_items()


func selected_inventory_item() -> String:
	return _inventory_cursor.selected_item_name


func deselect_inventory_item() -> void:
	_inventory_manager.deselect_all()


func set_selected_inventory_item(item_name: String) -> void:
	_inventory_manager.selected_item_name = item_name
