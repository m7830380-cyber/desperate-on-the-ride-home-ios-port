extends Control

const OPTION_LABEL_MAX_FONT_SIZE: = 40
const OPTION_LABEL_MIN_FONT_SIZE: = 18
const OPTION_ARROW_BUTTON_WIDTH: = 48.0

const OPTION_FULLSCREEN: = "fullscreen"
const OPTION_BGM: = "bgm"
const OPTION_SE: = "se"

const OPTION_ROW_NAME_KEY: = "name_key"
const OPTION_ROW_SETTING_KEY: = "setting_key"
const OPTION_ROW_VALUES: = "values"
const OPTION_ROW_DISPLAY_KEYS: = "display_keys"
const OPTION_ROW_WRAP: = "wrap"

const OPTION_VALUE_ON_OFF: = ["OPTION_OFF", "OPTION_ON"]
const OPTION_CHANGE_SOUND: = preload("res://data/se/system/OptionChangeClickSound.mp3")
const FLIPPED_BACKGROUND_LOCALES: = ["en", "ko", "zh"]

const ENDING_HINT_KEY_FORMAT: = "ENDING_HINT_%d"
const ENDING_TRIAL_KEY: = "ENDING_TRIAL"
const ENDING_UNLOCKED_KEY: = "ENDING_UNLOCKED"
const ENDING_HINT_INST_PC_KEY: = "ENDING_HINT_INST_PC"
const ENDING_HINT_INST_ANDROID_KEY: = "ENDING_HINT_INST_AND"
const UNLOCKED_THUMBNAIL_PATH_FORMAT: = "res://data/images/ui/thumbnail_hint_%d.webp"
const LOCKED_THUMBNAIL: = preload("res://data/images/ui/thumbnail_hint_lock.webp")

const OPTION_ROWS: = {
	OPTION_FULLSCREEN: {
		OPTION_ROW_NAME_KEY: "OPTION_FULLSCREEN", 
		OPTION_ROW_SETTING_KEY: "fullscreen_enabled", 
		OPTION_ROW_VALUES: [false, true], 
		OPTION_ROW_DISPLAY_KEYS: OPTION_VALUE_ON_OFF, 
		OPTION_ROW_WRAP: true, 
	}, 
	OPTION_BGM: {
		OPTION_ROW_NAME_KEY: "OPTION_BGM", 
		OPTION_ROW_SETTING_KEY: "bgm_volume", 
		OPTION_ROW_VALUES: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 
		OPTION_ROW_DISPLAY_KEYS: [], 
		OPTION_ROW_WRAP: false, 
	}, 
	OPTION_SE: {
		OPTION_ROW_NAME_KEY: "OPTION_SE", 
		OPTION_ROW_SETTING_KEY: "sfx_volume", 
		OPTION_ROW_VALUES: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 
		OPTION_ROW_DISPLAY_KEYS: [], 
		OPTION_ROW_WRAP: false, 
	}, 
}

@onready var main_pause_panel: Control = $Panel
@onready var ask_again_panel: Control = $ReturnMainMenu
@onready var background: TextureRect = $Background
@onready var pause_label: Label = $Panel / PauseLabel

@onready var option_fullscreen: HBoxContainer = $Panel / OptionList / Fullscreen
@onready var option_bgm: HBoxContainer = $Panel / OptionList / BGM
@onready var option_se: HBoxContainer = $Panel / OptionList / SE

@onready var ending_1: TextureRect = $Panel / Column1 / Ending1
@onready var ending_2: TextureRect = $Panel / Column2 / Ending2
@onready var ending_3: TextureRect = $Panel / Column1 / Ending3
@onready var ending_4: TextureRect = $Panel / Column2 / Ending4
@onready var ending_5: TextureRect = $Panel / Column1 / Ending5
@onready var ending_6: TextureRect = $Panel / Column2 / Ending6
@onready var ending_7: TextureRect = $Panel / Column1 / Ending7
@onready var ending_8: TextureRect = $Panel / Column2 / Ending8
@onready var ending_hint_label: Label = $Panel / DescriptionLabel

var _option_row_nodes: Dictionary = {}
var _ending_nodes: Array[TextureRect] = []
var _pause_label_base_position: = Vector2.ZERO
var _ending_hint_label_base_position: = Vector2.ZERO

func _ready() -> void :
	_option_row_nodes = {
		OPTION_FULLSCREEN: option_fullscreen, 
		OPTION_BGM: option_bgm, 
		OPTION_SE: option_se, 
	}
	_ending_nodes = [
		ending_1, 
		ending_2, 
		ending_3, 
		ending_4, 
		ending_5, 
		ending_6, 
		ending_7, 
		ending_8, 
	]

	_pause_label_base_position = pause_label.position
	_ending_hint_label_base_position = ending_hint_label.position
	_apply_platform_option_visibility()
	_apply_locale_layout()
	_connect_option_buttons()
	_connect_ending_hover()
	initialize_pause_panel()

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_locale_layout()
		_update_option_rows()
		_request_fit_all_option_row_labels()
		_set_default_ending_hint_text()

func initialize_pause_panel() -> void :
	main_pause_panel.visible = true
	ask_again_panel.visible = false
	_set_default_ending_hint_text()
	_update_ending_textures()
	_update_option_rows()
	_apply_text_label_y_offsets()
	_request_fit_all_option_row_labels()

func _connect_option_buttons() -> void :
	for option_id in _option_row_nodes.keys():
		var row: HBoxContainer = _option_row_nodes[option_id]
		if not row.visible:
			continue
		var left_button: TextureButton = row.get_node("LeftButton")
		var right_button: TextureButton = row.get_node("RightButton")
		if not left_button.pressed.is_connected(_on_option_button_pressed.bind(option_id, -1)):
			left_button.pressed.connect(_on_option_button_pressed.bind(option_id, -1))
		if not right_button.pressed.is_connected(_on_option_button_pressed.bind(option_id, 1)):
			right_button.pressed.connect(_on_option_button_pressed.bind(option_id, 1))

func _connect_ending_hover() -> void :
	for index in range(_ending_nodes.size()):
		var ending_index: = index + 1
		var node: TextureRect = _ending_nodes[index]
		node.mouse_filter = Control.MOUSE_FILTER_STOP
		if not node.mouse_entered.is_connected(_on_ending_mouse_entered.bind(ending_index)):
			node.mouse_entered.connect(_on_ending_mouse_entered.bind(ending_index))
		if not node.mouse_exited.is_connected(_on_ending_mouse_exited):
			node.mouse_exited.connect(_on_ending_mouse_exited)

func _on_option_button_pressed(option_id: String, direction: int) -> void :
	var row_data: Dictionary = OPTION_ROWS[option_id]
	var setting_key: String = row_data[OPTION_ROW_SETTING_KEY]
	var values: Array = row_data[OPTION_ROW_VALUES]
	var current_value = SaveManager.config.get_value("Settings", setting_key, values[0])
	var current_index: = values.find(current_value)

	if current_index == -1:
		current_index = 0

	var wrap_enabled: bool = row_data.get(OPTION_ROW_WRAP, true)
	var next_index: = posmod(current_index + direction, values.size()) if wrap_enabled else clampi(current_index + direction, 0, values.size() - 1)
	var next_value = values[next_index]

	if next_value == current_value:
		return

	AudioManager.play_any_sfx(OPTION_CHANGE_SOUND)
	SaveManager.update_setting(setting_key, next_value)
	_update_option_row(option_id)
	_request_fit_option_row_labels(option_id)

func _on_ending_mouse_entered(ending_index: int) -> void :
	if _is_trial_locked_ending(ending_index):
		ending_hint_label.text = tr(ENDING_TRIAL_KEY)
	elif SaveManager.is_ending_unlocked(ending_index):
		ending_hint_label.text = tr(ENDING_UNLOCKED_KEY)
	else:
		ending_hint_label.text = tr(ENDING_HINT_KEY_FORMAT % ending_index)

func _on_ending_mouse_exited() -> void :
	_set_default_ending_hint_text()

func _set_default_ending_hint_text() -> void :
	if _are_all_endings_available():
		ending_hint_label.text = ""
		return
	ending_hint_label.text = tr(ENDING_HINT_INST_ANDROID_KEY if _is_mobile_platform() else ENDING_HINT_INST_PC_KEY)

func _are_all_endings_available() -> bool:
	for ending_index in range(1, SaveManager.ENDING_COUNT + 1):
		if not _is_ending_thumbnail_unlocked(ending_index):
			return false
	return true

func _update_ending_textures() -> void :
	for index in range(_ending_nodes.size()):
		var ending_index: = index + 1
		var node: TextureRect = _ending_nodes[index]
		if _is_ending_thumbnail_unlocked(ending_index):
			node.texture = load(UNLOCKED_THUMBNAIL_PATH_FORMAT % ending_index)
		else:
			node.texture = LOCKED_THUMBNAIL

func _is_ending_thumbnail_unlocked(ending_index: int) -> bool:
	if _is_trial_locked_ending(ending_index):
		return false
	return SaveManager.is_ending_unlocked(ending_index)

func _update_option_rows() -> void :
	for option_id in _option_row_nodes.keys():
		_update_option_row(option_id)

func _update_option_row(option_id: String) -> void :
	var row_data: Dictionary = OPTION_ROWS[option_id]
	var row: HBoxContainer = _option_row_nodes[option_id]
	if not row.visible:
		return

	var option_name: Label = row.get_node("OptionName")
	var option_value: Label = row.get_node("OptionValue")

	option_name.text = tr(row_data[OPTION_ROW_NAME_KEY])
	option_value.text = _get_option_display_text(row_data)
	_update_option_button_state(option_id)
	_fit_option_row_labels(option_id)

func _get_option_display_text(row_data: Dictionary) -> String:
	var setting_key: String = row_data[OPTION_ROW_SETTING_KEY]
	var values: Array = row_data[OPTION_ROW_VALUES]
	var display_keys: Array = row_data[OPTION_ROW_DISPLAY_KEYS]
	var current_value = SaveManager.config.get_value("Settings", setting_key, values[0])
	var current_index: = values.find(current_value)

	if current_index == -1:
		current_index = 0

	if display_keys.is_empty():
		return str(values[current_index])

	return tr(display_keys[current_index])

func _update_option_button_state(option_id: String) -> void :
	var row_data: Dictionary = OPTION_ROWS[option_id]
	var row: HBoxContainer = _option_row_nodes[option_id]
	var left_button: TextureButton = row.get_node("LeftButton")
	var right_button: TextureButton = row.get_node("RightButton")
	var wrap_enabled: bool = row_data.get(OPTION_ROW_WRAP, true)

	if wrap_enabled:
		_set_option_button_enabled(left_button, true)
		_set_option_button_enabled(right_button, true)
		return

	var setting_key: String = row_data[OPTION_ROW_SETTING_KEY]
	var values: Array = row_data[OPTION_ROW_VALUES]
	var current_value = SaveManager.config.get_value("Settings", setting_key, values[0])
	var current_index: = values.find(current_value)

	if current_index == -1:
		current_index = 0

	_set_option_button_enabled(left_button, current_index > 0)
	_set_option_button_enabled(right_button, current_index < values.size() - 1)

func _set_option_button_enabled(button: TextureButton, is_enabled: bool) -> void :
	button.disabled = not is_enabled
	button.modulate.a = 1.0 if is_enabled else 0.3

func _apply_platform_option_visibility() -> void :
	var fullscreen_available: = not _is_mobile_platform()
	option_fullscreen.visible = fullscreen_available
	_set_option_row_interactive(option_fullscreen, fullscreen_available)

func _is_mobile_platform() -> bool:
	return OS.get_name() in ["Android", "iOS"]

func _set_option_row_interactive(row: HBoxContainer, is_enabled: bool) -> void :
	var left_button: TextureButton = row.get_node("LeftButton")
	var right_button: TextureButton = row.get_node("RightButton")
	left_button.disabled = not is_enabled
	right_button.disabled = not is_enabled
	left_button.modulate.a = 1.0 if is_enabled else 0.3
	right_button.modulate.a = 1.0 if is_enabled else 0.3

func _apply_locale_layout() -> void :
	var locale: = TranslationServer.get_locale().get_slice("_", 0)
	background.flip_h = locale in FLIPPED_BACKGROUND_LOCALES
	_apply_text_label_y_offsets()

func _is_trial_locked_ending(ending_index: int) -> bool:
	return GlobalVar.is_trial_version and ending_index >= 3

func _apply_text_label_y_offsets() -> void :
	pause_label.position = Vector2(_pause_label_base_position.x, _pause_label_base_position.y + GlobalVar.get_label_text_y_offset(pause_label))
	ending_hint_label.position = Vector2(_ending_hint_label_base_position.x, _ending_hint_label_base_position.y + GlobalVar.get_label_text_y_offset(ending_hint_label))

func _fit_option_row_labels(option_id: String) -> void :
	if not _option_row_nodes.has(option_id):
		return

	var row: HBoxContainer = _option_row_nodes[option_id]
	if not row.visible:
		return

	var label_width: float = _get_option_label_slot_width(row)
	if label_width <= 0.0:
		return

	_fit_label_font_size(row.get_node("OptionName") as Label, label_width)
	_fit_label_font_size(row.get_node("OptionValue") as Label, label_width)

func _fit_all_option_row_labels() -> void :
	for option_id in _option_row_nodes.keys():
		_fit_option_row_labels(option_id)

func _request_fit_option_row_labels(option_id: String) -> void :
	if visible:
		_fit_option_row_labels_after_layout(option_id)

func _request_fit_all_option_row_labels() -> void :
	if visible:
		_fit_all_option_row_labels_after_layout()

func _fit_option_row_labels_after_layout(option_id: String) -> void :
	await get_tree().process_frame
	await get_tree().process_frame

	if visible:
		_fit_option_row_labels(option_id)
		_apply_text_label_y_offsets()

func _fit_all_option_row_labels_after_layout() -> void :
	await get_tree().process_frame
	await get_tree().process_frame

	if visible:
		_fit_all_option_row_labels()
		_apply_text_label_y_offsets()

func _get_option_label_slot_width(row: HBoxContainer) -> float:
	var separation: float = float(row.get_theme_constant("separation"))
	var button_width: float = OPTION_ARROW_BUTTON_WIDTH * 2.0
	var separation_width: float = separation * 3.0
	var available_width: float = (row.size.x - button_width - separation_width) / 2.0
	return available_width if available_width > 0.0 else 0.0

func _fit_label_font_size(label: Label, available_width: float) -> void :
	if not label:
		return

	label.clip_text = true
	label.custom_minimum_size = Vector2(available_width, label.custom_minimum_size.y)
	label.size = Vector2(available_width, label.size.y)

	if available_width <= 0.0:
		return

	var font: Font = label.get_theme_font("font")
	var font_size: = OPTION_LABEL_MAX_FONT_SIZE

	while font_size >= OPTION_LABEL_MIN_FONT_SIZE:
		var text_width: = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		if text_width <= available_width:
			break

		font_size -= 1

	font_size = maxi(font_size, OPTION_LABEL_MIN_FONT_SIZE)
	label.add_theme_font_size_override("font_size", font_size)
	label.clip_text = true
