extends Control

const UNLOCKED_THUMBNAIL_PATH_FORMAT: = "res://data/images/ui/thumbnail_%d.webp"
const HOVER_THUMBNAIL_PATH_FORMAT: = "res://data/images/ui/thumbnail_hover_%d.webp"
const LOCKED_THUMBNAIL: = preload("res://data/images/ui/thumbnail_lock.webp")
const ENDING_DESC_KEY_FORMAT: = "ENDING_DESC_%d"
const ENDING_HINT_KEY_FORMAT: = "ENDING_HINT_%d"
const ENDING_TRIAL_KEY: = "ENDING_TRIAL"
const TAPE_SFX: = preload("res://data/se/life/tape.ogg")
const CUTSCENE_PLAYER_SCENE: = "res://scenes/CutscenePlayer.tscn"
const MAIN_TREE_SCENE: = "res://scenes/MainTree.tscn"
const CUTSCENE_ID_FORMAT: = "ending%d"
const CUTSCENE_TRANSITION_TYPE: int = 5
const CUTSCENE_TRANSITION_DURATION: = 0.8
const HFLIP_ENDINGS: Array[int] = [6]
const HFLIP_LOCALES: Array[String] = ["ko", "en", "zh"]

@onready var ending_1: CustomButton = $HBox1 / Ending1
@onready var ending_2: CustomButton = $HBox1 / Ending2
@onready var ending_3: CustomButton = $HBox2 / Ending3
@onready var ending_4: CustomButton = $HBox2 / Ending4
@onready var ending_5: CustomButton = $HBox3 / Ending5
@onready var ending_6: CustomButton = $HBox3 / Ending6
@onready var ending_7: CustomButton = $HBox4 / Ending7
@onready var ending_8: CustomButton = $HBox4 / Ending8
@onready var description_label: Label = $DescriptionLabel

var _description_label_base_position: = Vector2.ZERO
var _ending_buttons: Array[CustomButton] = []
var _selected_mobile_ending_index: = 0
var _selected_mobile_button: CustomButton = null
var _mobile_touch_handled_frame: = -1
var _is_transition_started: = false

func _ready() -> void :
	_description_label_base_position = description_label.position
	_apply_locale_text_y_offsets()
	description_label.text = ""

	_ending_buttons = [
		ending_1, 
		ending_2, 
		ending_3, 
		ending_4, 
		ending_5, 
		ending_6, 
		ending_7, 
		ending_8, 
	]

	for index in range(_ending_buttons.size()):
		var ending_index: = index + 1
		_update_ending_texture(_ending_buttons[index], ending_index)
		_ending_buttons[index].mouse_entered.connect(_on_ending_mouse_entered.bind(ending_index))
		_ending_buttons[index].mouse_exited.connect(_on_ending_mouse_exited.bind(_ending_buttons[index], ending_index))
		_ending_buttons[index].pressed.connect(_on_ending_pressed.bind(_ending_buttons[index], ending_index))

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_locale_text_y_offsets()
		_update_ending_textures()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and visible:
		_reset_interaction_state()

func _input(event: InputEvent) -> void :
	if not visible:
		return

	if not _is_mobile_platform():
		return

	if _mobile_touch_handled_frame == Engine.get_process_frames():
		return

	if event is InputEventScreenTouch:
		var touch_event: = event as InputEventScreenTouch
		if touch_event.pressed:
			if _handle_mobile_touch(touch_event.position):
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse_event: = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _handle_mobile_touch(mouse_event.position):
				get_viewport().set_input_as_handled()

func _on_ending_mouse_entered(ending_index: int) -> void :
	if _is_mobile_platform():
		return
	_set_description_for_ending(ending_index)
	if _is_ending_replay_available(ending_index):
		_set_ending_selected_texture(_ending_buttons[ending_index - 1], ending_index, true)

func _on_ending_mouse_exited(button: CustomButton, ending_index: int) -> void :
	if _is_mobile_platform():
		return
	if _is_transition_started:
		return
	if _is_ending_replay_available(ending_index):
		_set_ending_selected_texture(button, ending_index, false)
	description_label.text = ""

func _on_ending_pressed(button: CustomButton, ending_index: int) -> void :
	if _is_mobile_platform():
		if _mobile_touch_handled_frame == Engine.get_process_frames():
			return

		_mobile_touch_handled_frame = Engine.get_process_frames()
		if _selected_mobile_ending_index == ending_index and _is_ending_replay_available(ending_index):
			_start_cutscene_transition(button, ending_index)
		else:
			_select_mobile_ending(button, ending_index)
		return

	if not _is_ending_replay_available(ending_index):
		return

	_start_cutscene_transition(button, ending_index)

func _start_cutscene_transition(button: CustomButton, ending_index: int) -> void :
	_is_transition_started = true
	button.disabled = true
	_set_ending_selected_texture(button, ending_index, true)
	AudioManager.play_any_sfx(TAPE_SFX)
	GlobalVar.play_cutscene_id = CUTSCENE_ID_FORMAT % ending_index
	GlobalVar.auto_transition_after_cutscene = MAIN_TREE_SCENE
	GlobalVar.open_replay_panel_on_main = true
	GlobalVar.last_transition_type = CUTSCENE_TRANSITION_TYPE
	GlobalVar.last_transition_duration = CUTSCENE_TRANSITION_DURATION

	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(CUTSCENE_PLAYER_SCENE, CUTSCENE_TRANSITION_TYPE, CUTSCENE_TRANSITION_DURATION)
	else:
		get_tree().change_scene_to_file(CUTSCENE_PLAYER_SCENE)

func _update_ending_texture(button: CustomButton, ending_index: int) -> void :
	var is_unlocked: = _is_ending_replay_available(ending_index)
	button.disabled = not is_unlocked
	button.flip_h = _should_flip_ending_thumbnail(ending_index)

	if is_unlocked:
		button.texture_normal = load(UNLOCKED_THUMBNAIL_PATH_FORMAT % ending_index)
		button.texture_hover = load(HOVER_THUMBNAIL_PATH_FORMAT % ending_index)
		button.texture_pressed = button.texture_hover
	else:
		button.texture_normal = LOCKED_THUMBNAIL
		button.texture_hover = null
		button.texture_pressed = null

	_set_button_full_alpha(button)
	_set_ending_selected_texture(button, ending_index, _selected_mobile_ending_index == ending_index and is_unlocked)

func _update_ending_textures() -> void :
	for index in range(_ending_buttons.size()):
		_update_ending_texture(_ending_buttons[index], index + 1)

func _should_flip_ending_thumbnail(ending_index: int) -> bool:
	return ending_index in HFLIP_ENDINGS and _get_current_language() in HFLIP_LOCALES

func _get_current_language() -> String:
	return TranslationServer.get_locale().get_slice("_", 0)

func _handle_mobile_touch(_global_position: Vector2) -> bool:
	_mobile_touch_handled_frame = Engine.get_process_frames()
	var ending_index: int = _get_ending_index_at_position(_global_position)
	if ending_index <= 0:
		_clear_mobile_selection()
		return false

	var button: CustomButton = _ending_buttons[ending_index - 1]
	if _selected_mobile_ending_index == ending_index and _is_ending_replay_available(ending_index):
		_start_cutscene_transition(button, ending_index)
	else:
		_select_mobile_ending(button, ending_index)
	return true

func _is_ending_replay_available(ending_index: int) -> bool:
	if _is_trial_locked_ending(ending_index):
		return false
	return SaveManager.is_ending_unlocked(ending_index)

func _is_trial_locked_ending(ending_index: int) -> bool:
	return GlobalVar.is_trial_version and ending_index >= 3

func _apply_locale_text_y_offsets() -> void :
	description_label.position = Vector2(_description_label_base_position.x, _description_label_base_position.y + GlobalVar.get_label_text_y_offset(description_label))

func _select_mobile_ending(button: CustomButton, ending_index: int) -> void :
	if _selected_mobile_button and _selected_mobile_button != button and _is_ending_replay_available(_selected_mobile_ending_index):
		_set_ending_selected_texture(_selected_mobile_button, _selected_mobile_ending_index, false)

	_selected_mobile_button = button
	_selected_mobile_ending_index = ending_index
	_set_description_for_ending(ending_index)
	if _is_ending_replay_available(ending_index):
		_set_ending_selected_texture(button, ending_index, true)

func _clear_mobile_selection() -> void :
	for index in range(_ending_buttons.size()):
		var ending_index: = index + 1
		if _is_ending_replay_available(ending_index):
			_set_ending_selected_texture(_ending_buttons[index], ending_index, false)

	_selected_mobile_button = null
	_selected_mobile_ending_index = 0
	description_label.text = ""

func _reset_interaction_state() -> void :
	_is_transition_started = false
	for index in range(_ending_buttons.size()):
		var ending_index: = index + 1
		if _is_ending_replay_available(ending_index):
			_set_ending_selected_texture(_ending_buttons[index], ending_index, false)
		_set_button_full_alpha(_ending_buttons[index])

	_selected_mobile_button = null
	_selected_mobile_ending_index = 0
	description_label.text = ""

func _set_description_for_ending(ending_index: int) -> void :
	if _is_trial_locked_ending(ending_index):
		description_label.text = tr(ENDING_TRIAL_KEY)
	elif SaveManager.is_ending_unlocked(ending_index):
		description_label.text = tr(ENDING_DESC_KEY_FORMAT % ending_index)
	else:
		description_label.text = tr(ENDING_HINT_KEY_FORMAT % ending_index)

func _set_ending_selected_texture(button: CustomButton, ending_index: int, is_selected: bool) -> void :
	if not _is_ending_replay_available(ending_index):
		return

	var texture_path: String = HOVER_THUMBNAIL_PATH_FORMAT if is_selected else UNLOCKED_THUMBNAIL_PATH_FORMAT
	button.texture_normal = load(texture_path % ending_index)

func _set_button_full_alpha(button: CustomButton) -> void :
	var color: = button.modulate
	color.a = 1.0
	button.modulate = color

func _is_position_inside_ending_button(_global_position: Vector2) -> bool:
	return _get_ending_index_at_position(_global_position) > 0

func _get_ending_index_at_position(_global_position: Vector2) -> int:
	for index in range(_ending_buttons.size()):
		var button: CustomButton = _ending_buttons[index]
		if button and button.get_global_rect().has_point(_global_position):
			return index + 1
	return 0

func _is_mobile_platform() -> bool:
	var os_name: = OS.get_name()
	return os_name == "Android" or os_name == "iOS"
