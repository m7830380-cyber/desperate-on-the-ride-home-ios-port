extends Node

var is_trial_version: bool = false

var debug_mode_enabled: bool = false

const DEFAULT_WINDOW_TITLE: = "Desperate on the Ride Home"
const BG_LOOP_WIDTH: float = 540.0
const BG_FAR_SCROLL_SPEED: float = 5.0
const BG_MED_SCROLL_SPEED: float = 16.0
const BG_NEAR_SCROLL_SPEED: float = 1000.0
const LOCALE_TEXT_Y_OFFSET_RATIOS: = {
	"ja": 0.0, 
	"en": 0.0, 
	"ko": 8.0 / 36.0, 
	"zh": 2.0 / 36.0, 
}
const TRIAL_WINDOW_TITLES: = {
	"en": "Desperate on the Ride Home (Trial)", 
	"ko": "차에서 응가 참는 이야기 (체험판)", 
	"ja": "車の中でうん〇我慢する話 (体験版)", 
	"zh": "回家路上的憋便危机 (试玩版)", 
}

var bgm_volume: int = 10
var sfx_volume: int = 10
var difficulty_index: int = 1
var dialogue_progression_index: int = 0
var fullscreen_enabled: bool = false
var resolution_index: int = 0

var apply_censor: bool = true
var censor_line: bool = false
var play_cutscene_id: String = ""
var chained_cutscene_id: String = ""
var auto_transition_after_cutscene: String = ""
var open_replay_panel_on_main: bool = false
var show_cutscene_end_ui: bool = true
var last_transition_type: int = 0
var last_transition_duration: float = 0.5

func _ready() -> void :
	refresh_window_title_deferred()

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_window_title_deferred()

func refresh_window_title_deferred() -> void :
	await get_tree().process_frame
	await get_tree().process_frame
	_update_window_title()

func _update_window_title() -> void :
	var localized_names: Dictionary = ProjectSettings.get_setting("application/config/name_localized", {})
	var language: = TranslationServer.get_locale().get_slice("_", 0)
	var title: String = localized_names.get(language, "")

	if title == "":
		title = localized_names.get("en", DEFAULT_WINDOW_TITLE)

	if is_trial_version:
		title = TRIAL_WINDOW_TITLES.get(language, TRIAL_WINDOW_TITLES.get("en", title))

	DisplayServer.window_set_title(title)

func get_locale_text_y_offset_ratio(locale: String = "") -> float:
	var language: String = locale.get_slice("_", 0) if locale != "" else TranslationServer.get_locale().get_slice("_", 0)
	return float(LOCALE_TEXT_Y_OFFSET_RATIOS.get(language, 0.0))

func get_text_y_offset_for_font_size(font_size: int, locale: String = "") -> float:
	return float(font_size) * get_locale_text_y_offset_ratio(locale)

func get_label_text_y_offset(label: Control, locale: String = "") -> float:
	return get_text_y_offset_for_font_size(get_label_font_size(label), locale)

func get_label_font_size(label: Control) -> int:
	if label == null:
		return 0

	if label is RichTextLabel:
		var rich_text_label: = label as RichTextLabel
		var rich_font_size: = rich_text_label.get_theme_font_size("normal_font_size")
		if rich_font_size <= 0:
			rich_font_size = rich_text_label.get_theme_font_size("font_size")
		return rich_font_size

	if label is Label:
		var plain_label: = label as Label
		return plain_label.get_theme_font_size("font_size")

	return label.get_theme_font_size("font_size")
