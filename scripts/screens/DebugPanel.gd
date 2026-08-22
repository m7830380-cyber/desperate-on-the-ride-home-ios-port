extends Control

const UNLOCKED_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const LOCKED_COLOR: Color = Color(1.0, 0.0, 0.0, 1.0)
const DEBUG_INACTIVE_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const DEBUG_ACTIVE_COLOR: Color = Color(1.0, 0.0, 0.0, 1.0)
const MOBILE_PLATFORMS: Array[String] = ["Android", "iOS"]

@onready var ending1: Label = $"Endings/1"
@onready var ending2: Label = $"Endings/2"
@onready var ending3: Label = $"Endings/3"
@onready var ending4: Label = $"Endings/4"
@onready var ending5: Label = $"Endings/5"
@onready var ending6: Label = $"Endings/6"
@onready var ending7: Label = $"Endings/7"
@onready var ending8: Label = $"Endings/8"

@onready var ending_labels: Array[Label] = [
	ending1, 
	ending2, 
	ending3, 
	ending4, 
	ending5, 
	ending6, 
	ending7, 
	ending8, 
]
@onready var activate_debug: Label = $"GameDebug"

func _ready() -> void :
	for index in range(ending_labels.size()):
		var label: Label = ending_labels[index]
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_update_ending_label_color(index + 1)

	activate_debug.mouse_filter = Control.MOUSE_FILTER_STOP
	activate_debug.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_activate_debug_color()

func _input(event: InputEvent) -> void :
	var touch_position: Vector2 = _get_confirm_event_position(event)
	if touch_position == Vector2.INF:
		return

	if activate_debug.get_global_rect().has_point(touch_position):
		_toggle_debug_mode()
		get_viewport().set_input_as_handled()
		return

	var ending_index: int = _get_ending_index_at_position(touch_position)
	if ending_index > 0:
		_toggle_ending(ending_index)
		get_viewport().set_input_as_handled()

func _get_confirm_event_position(event: InputEvent) -> Vector2:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and not _is_mobile_environment() and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		return mouse_event.position

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null and touch_event.pressed:
		return touch_event.position

	return Vector2.INF

func _get_ending_index_at_position(screen_position: Vector2) -> int:
	for index in range(ending_labels.size()):
		if ending_labels[index].get_global_rect().has_point(screen_position):
			return index + 1

	return 0

func _toggle_ending(ending_index: int) -> void :
	if SaveManager.is_ending_unlocked(ending_index):
		SaveManager.lock_ending(ending_index)
	else:
		SaveManager.unlock_ending(ending_index)

	_update_ending_label_color(ending_index)

func _update_ending_label_color(ending_index: int) -> void :
	var label: Label = ending_labels[ending_index - 1]
	var color: Color = UNLOCKED_COLOR if SaveManager.is_ending_unlocked(ending_index) else LOCKED_COLOR
	label.add_theme_color_override("font_color", color)

func _toggle_debug_mode() -> void :
	GlobalVar.debug_mode_enabled = not GlobalVar.debug_mode_enabled
	_update_activate_debug_color()

func _update_activate_debug_color() -> void :
	var color: Color = DEBUG_ACTIVE_COLOR if GlobalVar.debug_mode_enabled else DEBUG_INACTIVE_COLOR
	activate_debug.add_theme_color_override("font_color", color)

func _is_mobile_environment() -> bool:
	return OS.get_name() in MOBILE_PLATFORMS
