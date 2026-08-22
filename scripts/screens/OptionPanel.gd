extends Control

const ACTIVE_LANGUAGE_ALPHA: = 1.0
const INACTIVE_LANGUAGE_ALPHA: = 0.35
const OPTION_LABEL_MAX_FONT_SIZE: = 40
const OPTION_LABEL_MIN_FONT_SIZE: = 18
const OPTION_ARROW_BUTTON_WIDTH: = 48.0

const OPTION_FULLSCREEN: = "fullscreen"
const OPTION_BGM: = "bgm"
const OPTION_SE: = "se"
const OPTION_DIALOGUE: = "dialogue"
const OPTION_CENSORSHIP: = "censorship"
const OPTION_DIFFICULTY: = "difficulty"

const OPTION_ROW_NAME_KEY: = "name_key"
const OPTION_ROW_SETTING_KEY: = "setting_key"
const OPTION_ROW_VALUES: = "values"
const OPTION_ROW_DISPLAY_KEYS: = "display_keys"
const OPTION_ROW_WRAP: = "wrap"

const OPTION_VALUE_ON_OFF: = ["OPTION_OFF", "OPTION_ON"]
const OPTION_VALUE_DIALOGUE: = ["OPTION_DIAG_CLICK", "OPTION_DIAG_AUTO_SLOW", "OPTION_DIAG_AUTO_FAST"]
const OPTION_VALUE_DIALOGUE_TOUCH: = "OPTION_DIAG_TOUCH"
const OPTION_VALUE_CENSORSHIP: = ["OPTION_CENSOR_WHITE_LINE", "OPTION_CENSOR_MOSAIC"]
const OPTION_VALUE_DIFFICULTY: = ["OPTION_DIFFICULTY_EASY", "OPTION_DIFFICULTY_NORMAL", "OPTION_DIFFICULTY_HARD", "OPTION_DIFFICULTY_VERYEASY"]
const OPTION_CHANGE_SOUND: = preload("res://data/se/system/OptionChangeClickSound.mp3")
const LICENSE_TEXT_PATH: = "res://data/texts/License.txt"

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
	OPTION_DIALOGUE: {
		OPTION_ROW_NAME_KEY: "OPTION_DIAG", 
		OPTION_ROW_SETTING_KEY: "dialogue_progression_index", 
		OPTION_ROW_VALUES: [0, 1, 2], 
		OPTION_ROW_DISPLAY_KEYS: OPTION_VALUE_DIALOGUE, 
		OPTION_ROW_WRAP: true, 
	}, 
	OPTION_CENSORSHIP: {
		OPTION_ROW_NAME_KEY: "OPTION_CENSOR", 
		OPTION_ROW_SETTING_KEY: "censor_line", 
		OPTION_ROW_VALUES: [true, false], 
		OPTION_ROW_DISPLAY_KEYS: OPTION_VALUE_CENSORSHIP, 
		OPTION_ROW_WRAP: true, 
	}, 
	OPTION_DIFFICULTY: {
		OPTION_ROW_NAME_KEY: "OPTION_DIFFICULTY", 
		OPTION_ROW_SETTING_KEY: "difficulty_index", 
		OPTION_ROW_VALUES: [0, 1, 2, 3], 
		OPTION_ROW_DISPLAY_KEYS: OPTION_VALUE_DIFFICULTY, 
		OPTION_ROW_WRAP: true, 
	}, 
}

@onready var button_ja: TextureButton = $OptionList / Language / ja
@onready var button_ko: TextureButton = $OptionList / Language / ko
@onready var button_en: TextureButton = $OptionList / Language / en
@onready var button_zh: TextureButton = $OptionList / Language / zh

@onready var option_fullscreen: HBoxContainer = $OptionList / Fullscreen
@onready var option_bgm: HBoxContainer = $OptionList / BGM
@onready var option_se: HBoxContainer = $OptionList / SE
@onready var option_dialogue: HBoxContainer = $OptionList / Dialogue
@onready var option_censorship: HBoxContainer = $OptionList / Censorship
@onready var option_difficulty: HBoxContainer = $OptionList / Difficulty

@onready var chinese_note: Label = $ChineseNote
@onready var option_list: VBoxContainer = $OptionList
@onready var option_value_note: Label = $OptionValue
@onready var license_button: TextureButton = $License
@onready var close_license_button: TextureButton = $Close

@export_group("License")
@export var license_text_label: RichTextLabel

var _language_buttons: Dictionary = {}
var _option_row_nodes: Dictionary = {}
var _current_locale: = ""

func _ready() -> void :
	visibility_changed.connect(_on_visibility_changed)

	_language_buttons = {
		"ja": button_ja, 
		"ko": button_ko, 
		"en": button_en, 
		"zh": button_zh, 
	}
	_option_row_nodes = {
		OPTION_FULLSCREEN: option_fullscreen, 
		OPTION_BGM: option_bgm, 
		OPTION_SE: option_se, 
		OPTION_DIALOGUE: option_dialogue, 
		OPTION_CENSORSHIP: option_censorship, 
		OPTION_DIFFICULTY: option_difficulty, 
	}
	_apply_platform_option_visibility()

	_current_locale = _get_current_language()
	_update_language_button_visuals()
	_connect_language_buttons()
	_connect_option_buttons()
	_update_option_rows()
	_load_license_text()
	_reset_license_view()

func _load_license_text() -> void :
	if license_text_label == null:
		return
	if not FileAccess.file_exists(LICENSE_TEXT_PATH):
		push_warning("OptionPanel: License text not found: %s" % LICENSE_TEXT_PATH)
		return

	var license_file: = FileAccess.open(LICENSE_TEXT_PATH, FileAccess.READ)
	if license_file == null:
		push_warning("OptionPanel: Failed to open license text: %s" % LICENSE_TEXT_PATH)
		return
	license_text_label.text = license_file.get_as_text()

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_current_locale = _get_current_language()
		_update_language_button_visuals()
		_update_option_rows()
		_request_fit_all_option_row_labels()

func _connect_language_buttons() -> void :
	for locale in _language_buttons.keys():
		var button: TextureButton = _language_buttons[locale]
		button.pressed.connect(_on_language_button_pressed.bind(locale))

func _connect_option_buttons() -> void :
	for option_id in _option_row_nodes.keys():
		var row: HBoxContainer = _option_row_nodes[option_id]
		if not row.visible:
			continue
		var left_button: TextureButton = row.get_node("LeftButton")
		var right_button: TextureButton = row.get_node("RightButton")
		left_button.pressed.connect(_on_option_button_pressed.bind(option_id, -1))
		right_button.pressed.connect(_on_option_button_pressed.bind(option_id, 1))

func _on_language_button_pressed(locale: String) -> void :
	if locale == _current_locale:
		return

	_current_locale = locale
	SaveManager.update_setting("locale", locale)
	_update_language_button_visuals()
	_update_option_rows()
	_request_fit_all_option_row_labels()

func _on_visibility_changed() -> void :
	if visible:
		_reset_license_view()
		_update_option_rows()
		_request_fit_all_option_row_labels()

func _reset_license_view() -> void :
	option_list.visible = true
	option_value_note.visible = true
	license_button.visible = true
	close_license_button.visible = false
	license_text_label.visible = false
	chinese_note.visible = _current_locale == "zh"
	license_text_label.scroll_to_line(0)

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

func _update_language_button_visuals() -> void :
	for locale in _language_buttons.keys():
		var button: TextureButton = _language_buttons[locale]
		button.modulate.a = ACTIVE_LANGUAGE_ALPHA if locale == _current_locale else INACTIVE_LANGUAGE_ALPHA
	chinese_note.visible = _current_locale == "zh"

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

	if row_data[OPTION_ROW_SETTING_KEY] == "dialogue_progression_index" and current_index == 0 and _is_mobile_platform():
		return tr(OPTION_VALUE_DIALOGUE_TOUCH)

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

func _set_option_button_enabled(button: TextureButton, enabled: bool) -> void :
	button.disabled = not enabled
	button.modulate.a = 1.0 if enabled else 0.3

func _get_current_language() -> String:
	return TranslationServer.get_locale().get_slice("_", 0)

func _apply_platform_option_visibility() -> void :
	option_fullscreen.visible = not _is_mobile_platform()

func _is_mobile_platform() -> bool:
	return OS.get_name() in ["Android", "iOS"]

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

func _fit_all_option_row_labels_after_layout() -> void :
	await get_tree().process_frame
	await get_tree().process_frame

	if visible:
		_fit_all_option_row_labels()

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
