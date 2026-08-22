extends Control

@export_group("SFX Settings")
@export var sfx_chara_state_list: Array[Resource] = []
@export var sfx_chara_state_interval_at_empty_gauge: float = 3.5
@export var sfx_chara_state_overlap_at_full_gauge: float = 1.0

@export var sfx_gas_emission_list: Array[Resource] = []
@export var sfx_gas_emission_interval_medium_gauge: float = 3.0
@export var sfx_gas_emission_interval_high_gauge: float = 1.0

@export var sfx_quiz_correct: Resource
@export var sfx_quiz_wrong: Resource

@export_group("BGM Settings")
@export var bgm: Resource

@export_group("Gas Effect Settings")
@export var gas_effect_duration: float = 4.0
@export var gas_effect_fade_in_duration: float = 0.8
@export var gas_effect_fade_out_duration: float = 1.2

@onready var bg_far: TextureRect = $Images / BgFar
@onready var bg_med: TextureRect = $Images / BgMed
@onready var bg_near: TextureRect = $Images / BgNear

@onready var car_seat: TextureRect = $Images / Car
@onready var char_portrait: TextureRect = $Images / Char
@onready var car_seat_front: TextureRect = $Images / Char / CarFront

@onready var gauge: TextureProgressBar = $GameHUD / Gauge
@onready var gauge_alert: TextureRect = $GameHUD / GaugeAlert
@onready var timer_gauge: TextureProgressBar = $GameHUD / Timer
@onready var remaining_time: Label = $GameHUD / Timer / Label
@onready var timer_indicator: TextureRect = $GameHUD / Timer / Indicator

@onready var gas_effects: Control = $Images / GasEffects
@onready var gas_emit_origin: Marker2D = $Images / EmitOrigin

@onready var breathe_effects: Control = $Images / BreatheEffects

@onready var quiz_question_panel: TextureRect = $GameHUD / QuizQuestionPanel
@onready var quiz_label: Label = $GameHUD / QuizQuestionPanel / Label

@onready var answer_1: TextureButton = $GameHUD / Answer1
@onready var answer_2: TextureButton = $GameHUD / Answer2
@onready var answer_3: TextureButton = $GameHUD / Answer3
@onready var answer_4: TextureButton = $GameHUD / Answer4
@onready var answer_1_keymap: Label = $GameHUD / Answer1 / Keymap
@onready var answer_2_keymap: Label = $GameHUD / Answer2 / Keymap
@onready var answer_3_keymap: Label = $GameHUD / Answer3 / Keymap
@onready var answer_4_keymap: Label = $GameHUD / Answer4 / Keymap
@onready var result_indicator: Label = $GameHUD / ResultIndicator


@onready var ask_container: Control = $GameHUD / AskContainer
@onready var ask_label: RichTextLabel = $GameHUD / AskContainer / AskDialogueBox / Label
@onready var yesno_container: HBoxContainer = $GameHUD / AskContainer / HBox
@onready var yes_button: TextureButton = $GameHUD / AskContainer / HBox / Yes
@onready var no_button: TextureButton = $GameHUD / AskContainer / HBox / No
@onready var yes_label: Label = $GameHUD / AskContainer / HBox / Yes / Label
@onready var no_label: Label = $GameHUD / AskContainer / HBox / No / Label
@onready var yes_keymap: Label = $GameHUD / AskContainer / HBox / Yes / Keymap
@onready var no_keymap: Label = $GameHUD / AskContainer / HBox / No / Keymap

@onready var ending_diagloauge_box: TextureRect = $GameHUD / EndingDiagloaugeBox
@onready var dialogue_label: RichTextLabel = $GameHUD / EndingDiagloaugeBox / Label

@onready var game_pause_button: TextureButton = $GameHUD / PauseButton
@onready var game_pause_menu: Control = $GameHUD / MiniGamePausePanel
@onready var game_resume_button: TextureButton = $GameHUD / MiniGamePausePanel / ResumeButton

@onready var debug_panel: Control = $GameHUD / DebugPanel
@onready var debug_timer_0: Button = $GameHUD / DebugPanel / TimerController / Timer0
@onready var debug_timer_10: Button = $GameHUD / DebugPanel / TimerController / Timer10
@onready var debug_timer_25: Button = $GameHUD / DebugPanel / TimerController / Timer25
@onready var debug_timer_45: Button = $GameHUD / DebugPanel / TimerController / Timer45
@onready var debug_lv_1: Button = $GameHUD / DebugPanel / GaugeController / Lv1
@onready var debug_lv_2: Button = $GameHUD / DebugPanel / GaugeController / Lv2
@onready var debug_lv_3: Button = $GameHUD / DebugPanel / GaugeController / Lv3
@onready var debug_lv_max: Button = $GameHUD / DebugPanel / GaugeController / Max
@onready var debug_ignore_answer: Button = $GameHUD / DebugPanel / IgnoreAnswer


const FLIPPED_DIRECTION_LOCALES: = ["ko", "en", "zh"]

const MAX_TIME: int = 45
const TIMER_INDICATOR_FULL_ROTATION_DEGREES: float = 360.0
const GAUGE_FILL_TIME: int = 18
const GAUGE_THRESHOLD_1: float = 1.0 / 3.0
const GAUGE_THRESHOLD_2: float = 2.0 / 3.0
const DEBUG_GAUGE_LEVEL_1_RATIO: float = 0.0
const DEBUG_GAUGE_LEVEL_2_RATIO: float = GAUGE_THRESHOLD_1
const DEBUG_GAUGE_LEVEL_3_RATIO: float = GAUGE_THRESHOLD_2
const DEBUG_GAUGE_ALMOST_MAX_RATIO: float = 0.99
const DEBUG_CONTROL_ENABLED_ALPHA: float = 1.0
const DEBUG_CONTROL_DISABLED_ALPHA: float = 0.5
const DEBUG_TOGGLE_INACTIVE_COLOR: Color = Color.WHITE
const DEBUG_TOGGLE_ACTIVE_COLOR: Color = Color.RED
const GAUGE_ALERT_FADE_CYCLE_DURATION: float = 1.0
const GAUGE_ALERT_MEDIUM_FADE_CYCLE_DURATION: float = 1.8
const GAUGE_ALERT_HIGH_MAX_ALPHA: float = 1.0
const GAUGE_ALERT_MEDIUM_MAX_ALPHA: float = 0.45
const GAME_START_POST_TRANSITION_WAIT_TIME: float = 1.5
const GAME_START_UI_FLY_DURATION: float = 0.5
const ENDING_CUTSCENE_WAIT_TIME: float = 2.5
const ENDING_CUTSCENE_UNSKIPPABLE_WAIT_TIME: float = 1.0
const ENDING_CUTSCENE_TRANSITION_DURATION: float = 0.8
const QUIZ_LABELS_FADE_DURATION: float = 0.5
const QUIZ_REFRESH_TEXT_CHANGE_DURATION: float = 1.0
const QUIZ_REFRESH_EASY_TEXT_STEPS: int = 5
const QUIZ_REFRESH_NORMAL_HARD_TEXT_STEPS: int = 7
const VERY_EASY_DIFFICULTY_INDEX: int = 3
const VERY_EASY_QUIZ_TEXT: String = "1+1"
const VERY_EASY_CORRECT_ANSWER: String = "2"
const VERY_EASY_WRONG_ANSWER: String = "0"
const VERY_EASY_DISABLED_ANSWER_ALPHA: float = 0.3
const ANSWER_BUTTON_FLY_DURATION: float = QUIZ_REFRESH_TEXT_CHANGE_DURATION * 0.5
const ANSWER_BUTTON_FLY_UP_DISTANCE: float = 160.0
const ANSWER_BUTTON_FLY_DOWN_DISTANCE: float = 220.0
const ANSWER_BUTTON_HOVER_LIFT_Y: float = 15.0
const ANSWER_BUTTON_HOVER_TWEEN_DURATION: float = 0.12
const ANSWER_KEYMAP_TEXTS: Array[String] = ["Q", "W", "E", "R"]
const ANSWER_KEYMAP_ACTIONS: Array[String] = ["answer_1", "answer_2", "answer_3", "answer_4"]
const YES_KEYMAP_TEXT: String = "Q"
const NO_KEYMAP_TEXT: String = "R"
const ASK_TRIGGER_REMAINING_TIME: float = 25.0
const DEBUG_ASK_PASSED_REMAINING_TIME: float = 24.99
const ASK_YESNO_WAIT_TIME: float = 0.5
const RESULT_INDICATOR_FADE_DURATION: float = 0.65
const RESULT_INDICATOR_FLY_Y: float = 28.0
const WRONG_ANSWER_PORTRAIT_DURATION: float = 1.5

const CORRECT_GAUGE_DELTA: float = -0.15
const WRONG_GAUGE_DELTA: float = 0.1

const QUIZ_CSV_PATH_FORMAT: String = "res://data/quiz/set_%d.csv"
const QUIZ_PROBLEM_SUFFIX: String = "=?"
const RESULT_TEXT_CORRECT: String = "Correct!"
const RESULT_TEXT_WRONG: String = "Wrong..."
const RESULT_COLOR_CORRECT: Color = Color(0.0, 0.9, 0.25, 1.0)
const RESULT_COLOR_WRONG: Color = Color(1.0, 0.1, 0.1, 1.0)
const ASK_TOILET_KEY_FORMAT: String = "GAME_ASK_TOILET_%d"
const ASK_ANSWER_YES_KEY_FORMAT: String = "GAME_ASK_ANSWER_YES_%d"
const ASK_ANSWER_NO_KEY_FORMAT: String = "GAME_ASK_ANSWER_NO_%d"
const RESPONSE_NO_KEY_FORMAT: String = "GAME_RESPONSE_NO_%d"
const GAME_END_KEY_FORMAT: String = "GAME_END_%d"
const CUTSCENE_PLAYER_SCENE: String = "res://scenes/CutscenePlayer.tscn"
const MAIN_TREE_SCENE: String = "res://scenes/MainTree.tscn"
const CUTSCENE_ID_FORMAT: String = "ending%d"
const CUTSCENE_TRANSITION_TYPE: int = 5
const RESPONSE_NO_AUTO_MODE_INDEX: int = 1

const GAME_RICH_TEXT_REPLACEMENTS: Dictionary = {
	"[sh0]": "[shake rate=10.0 level=2 connected=1]", 
	"[/sh0]": "[/shake]", 
	"[sh]": "[shake]", 
	"[/sh]": "[/shake]", 
	"[sh1]": "[shake]", 
	"[/sh1]": "[/shake]", 
	"[sh2]": "[shake rate=40.0 level=10 connected=1]", 
	"[/sh2]": "[/shake]", 
	"[sh3]": "[shake rate=60.0 level=15 connected=1]", 
	"[/sh3]": "[/shake]", 
}

const CAR_SHAKE_MAX_Y: float = 5.0
const CAR_SHAKE_INTERVAL_MIN: float = 0.04
const CAR_SHAKE_INTERVAL_MAX: float = 0.12
const CAR_SHAKE_SMOOTH_SPEED: float = 18.0
const CAR_SHAKE_STDDEV_RATIO: float = 0.33
const BREATHE_EFFECT_FADE_DURATION: float = 2.0

const GAUGE_TEXTURE_HEIGHT: int = 500
const GAUGE_TEXTURE_TRANSPARENT_MARGIN_BOTTOM: int = 8
const GAUGE_TEXTURE_TRANSPARENT_MARGIN_TOP: int = 62

const GAUGE_TEXTURE_OVER_LOW: String = "res://data/images/ui/gauge_bd1.webp"
const GAUGE_TEXTURE_OVER_MEDIUM: String = "res://data/images/ui/gauge_bd2.webp"
const GAUGE_TEXTURE_OVER_HIGH: String = "res://data/images/ui/gauge_bd3.webp"
const GAUGE_TEXTURE_PROGRESS_LOW: String = "res://data/images/ui/gauge_fill1.webp"
const GAUGE_TEXTURE_PROGRESS_MEDIUM: String = "res://data/images/ui/gauge_fill2.webp"
const GAUGE_TEXTURE_PROGRESS_HIGH: String = "res://data/images/ui/gauge_fill3.webp"

const CHAR_PORTRAIT_LOW_GAUGE_PATH: String = "res://data/images/cutscene_common/chara_001.webp"
const CHAR_PORTRAIT_MEDIUM_GAUGE_PATH: String = "res://data/images/cutscene_common/chara_004.webp"
const CHAR_PORTRAIT_HIGH_GAUGE_PATH: String = "res://data/images/cutscene_common/chara_005.webp"
const CHAR_PORTRAIT_ASKING_QUESTION_PATH: String = "res://data/images/cutscene_common/chara_002.webp"
const CHAR_PORTRAIT_WRONG_ANSWER_PATH: String = "res://data/images/cutscene_common/chara_007.webp"
const CHAR_PORTRAIT_ENDING_1_PATH: String = "res://data/images/cutscene_common/chara_008.webp"
const CHAR_PORTRAIT_LOW_GAUGE_DROP_PATH: String = "res://data/images/cutscene_common/chara_002.webp"
const CHAR_PORTRAIT_MEDIUM_GAUGE_DROP_PATH: String = "res://data/images/cutscene_common/chara_005.webp"
const CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH: String = "res://data/images/cutscene_common/chara_006.webp"

const RUNTIME_TEXTURE_PATHS: = [
	GAUGE_TEXTURE_OVER_LOW, 
	GAUGE_TEXTURE_OVER_MEDIUM, 
	GAUGE_TEXTURE_OVER_HIGH, 
	GAUGE_TEXTURE_PROGRESS_LOW, 
	GAUGE_TEXTURE_PROGRESS_MEDIUM, 
	GAUGE_TEXTURE_PROGRESS_HIGH, 
	CHAR_PORTRAIT_LOW_GAUGE_PATH, 
	CHAR_PORTRAIT_MEDIUM_GAUGE_PATH, 
	CHAR_PORTRAIT_HIGH_GAUGE_PATH, 
	CHAR_PORTRAIT_ASKING_QUESTION_PATH, 
	CHAR_PORTRAIT_WRONG_ANSWER_PATH, 
	CHAR_PORTRAIT_ENDING_1_PATH, 
	CHAR_PORTRAIT_LOW_GAUGE_DROP_PATH, 
	CHAR_PORTRAIT_MEDIUM_GAUGE_DROP_PATH, 
	CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH, 
]

enum GamePhase{
	STARTUP, 
	QUIZ, 
	ASK_TRANSITION, 
	ASK_WAITING, 
	NO_RESPONSE, 
	ENDING, 
}

enum GaugeState{
	LOW, 
	MEDIUM, 
	HIGH, 
}

var _bg_far_neutral_x: = 0.0
var _bg_med_neutral_x: = 0.0
var _bg_near_neutral_x: = 0.0
var _background_direction: = -1.0
var _is_layout_flipped: = false
var _car_seat_base_position: = Vector2.ZERO
var _char_portrait_base_position: = Vector2.ZERO
var _car_shake_timer: = 0.0
var _car_shake_next_interval: = 0.0
var _car_shake_current_y: = 0.0
var _car_shake_target_y: = 0.0
var _remaining_time: = float(MAX_TIME)
var _gauge_ratio: = 0.0
var _gauge_state: int = GaugeState.LOW
var _gauge_alert_tween: Tween = null
var _is_gauge_alert_looping: bool = false
var _gauge_alert_cycle_duration: float = 0.0
var _gauge_alert_max_alpha: float = 0.0
var _sfx_chara_state_bag: Array[Resource] = []
var _sfx_chara_state_last: Resource = null
var _sfx_chara_state_time_until_next: = 0.0
var _sfx_gas_emission_bag: Array[Resource] = []
var _sfx_gas_emission_last: Resource = null
var _sfx_gas_emission_time_until_next: = 0.0
var _paused_sfx_players: Array[AudioStreamPlayer] = []
var _gas_effect_bag: Array[TextureRect] = []
var _gas_effect_last: TextureRect = null
var _gas_effect_initial_rects: = {}
var _gas_effect_tweens: = {}
var _breathe_effect_list: Array[TextureRect] = []
var _breathe_effect_current: TextureRect = null
var _breathe_effect_tween: Tween = null
var _breathe_effect_initial_rects: = {}
var _gauge_landing_position: Vector2 = Vector2.ZERO
var _timer_landing_position: Vector2 = Vector2.ZERO
var _pause_button_landing_position: Vector2 = Vector2.ZERO
var _result_indicator_base_position: Vector2 = Vector2.ZERO
var _yesno_landing_position: Vector2 = Vector2.ZERO
var _ask_label_base_position: Vector2 = Vector2.ZERO
var _dialogue_label_base_position: Vector2 = Vector2.ZERO
var _answer_buttons: Array[TextureButton] = []
var _answer_keymap_labels: Array[Label] = []
var _answer_button_landing_positions: Dictionary = {}
var _answer_button_tween: Tween = null
var _answer_button_hover_tweens: Dictionary = {}
var _debug_control_buttons: Array[Button] = []
var _debug_ignore_answer_enabled: bool = false
var _quiz_entries: Array[Dictionary] = []
var _quiz_bag: Array[Dictionary] = []
var _quiz_difficulty_index: int = 1
var _texture_cache: Dictionary = {}
var _is_game_active: bool = false
var _is_game_paused: bool = false
var _is_quiz_transitioning: bool = false
var _is_gauge_paused: bool = false
var _is_timer_paused: bool = false
var _has_ask_sequence_started: bool = false
var _has_clicked_no: bool = false
var _is_ending_started: bool = false
var _is_ending_transition_started: bool = false
var _can_click_to_ending_transition: bool = false
var _can_click_skip_no_response_wait: bool = false
var _is_no_response_wait_skipped: bool = false
var _ending_index: int = 0
var _portrait_override_until_msec: int = 0
var _game_phase: int = GamePhase.STARTUP
var _result_indicator_tween: Tween = null
var _rx_game_wait_tag: RegEx = RegEx.new()
var _rx_game_bbcode_strip: RegEx = RegEx.new()

func _ready() -> void :
	randomize()
	_bg_far_neutral_x = bg_far.position.x
	_bg_med_neutral_x = bg_med.position.x
	_bg_near_neutral_x = bg_near.position.x
	_car_seat_base_position = car_seat.position
	_char_portrait_base_position = char_portrait.position
	_gauge_landing_position = gauge.position
	_timer_landing_position = timer_gauge.position
	_pause_button_landing_position = game_pause_button.position
	_result_indicator_base_position = result_indicator.position
	_yesno_landing_position = yesno_container.position
	_ask_label_base_position = ask_label.position
	_dialogue_label_base_position = dialogue_label.position

	_rx_game_wait_tag.compile("\\[(w|wait)(?::([^\\]]*))?\\]")
	_rx_game_bbcode_strip.compile("\\[[^\\]]*\\]")
	_preload_runtime_textures()
	_remaining_time = float(MAX_TIME)
	timer_gauge.min_value = 0.0
	timer_gauge.max_value = float(MAX_TIME)
	timer_gauge.step = 0.1
	_update_timer_indicator_pivot()
	_gauge_ratio = 0.0
	_initialize_gauge_alert()
	_car_shake_next_interval = randf_range(CAR_SHAKE_INTERVAL_MIN, CAR_SHAKE_INTERVAL_MAX)
	_car_shake_current_y = 0.0
	_car_shake_target_y = 0.0
	_sfx_chara_state_time_until_next = randf_range(0.0, sfx_chara_state_interval_at_empty_gauge)
	_sfx_gas_emission_time_until_next = randf_range(0.0, sfx_gas_emission_interval_medium_gauge)
	_initialize_gas_effects()
	_initialize_breathe_effects()
	_initialize_quiz_ui()
	_initialize_ask_ui()
	_initialize_pause_ui()
	_initialize_debug_ui()
	_connect_answer_buttons()
	_connect_ask_buttons()
	_connect_pause_buttons()
	_connect_debug_buttons()
	_load_quiz_data()

	_apply_locale_layout()
	_update_timer_display()
	_update_gauge_display(true)
	_start_breathe_effect_loop()
	call_deferred("_run_game_start_sequence")

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_locale_layout()
		_update_gauge_display(true)
	elif what == NOTIFICATION_RESIZED and is_node_ready():
		_update_timer_indicator_pivot()

func _process(delta: float) -> void :
	if _is_game_paused:
		return

	_update_background_scroll(delta)
	_update_car_shake(delta)

	if not _is_game_active:
		return

	_update_timer(delta)
	_update_gauge(delta)
	if _is_ending_started:
		return
	_update_sfx_chara_state_scheduler(delta)
	_update_sfx_gas_emission_scheduler(delta)

func _initialize_quiz_ui() -> void :
	_answer_buttons = [answer_1, answer_2, answer_3, answer_4]
	_answer_keymap_labels = [answer_1_keymap, answer_2_keymap, answer_3_keymap, answer_4_keymap]
	_cache_answer_button_landing_positions()
	_initialize_answer_keymap_labels()
	quiz_label.text = ""
	quiz_label.modulate.a = 0.0
	quiz_question_panel.visible = true
	quiz_question_panel.modulate.a = 0.0
	_move_answer_buttons_to_bottom(false)
	result_indicator.visible = false
	result_indicator.modulate.a = 0.0
	result_indicator.position = _result_indicator_base_position
	_set_answer_buttons_enabled(false)
	_move_start_ui_outside_viewport()

func _initialize_ask_ui() -> void :
	ask_container.visible = false
	ask_container.modulate.a = 0.0
	ask_label.text = ""
	yesno_container.visible = false
	yesno_container.modulate.a = 1.0
	yesno_container.position = _get_yesno_outside_position()
	yes_label.text = ""
	no_label.text = ""
	_initialize_yesno_keymap_labels()
	_set_yesno_buttons_enabled(false)
	ending_diagloauge_box.visible = false
	ending_diagloauge_box.modulate.a = 0.0
	dialogue_label.text = ""

func _connect_answer_buttons() -> void :
	for button in _answer_buttons:
		if not button.pressed.is_connected(_on_answer_pressed.bind(button)):
			button.pressed.connect(_on_answer_pressed.bind(button))
		if not button.mouse_entered.is_connected(_on_answer_mouse_entered.bind(button)):
			button.mouse_entered.connect(_on_answer_mouse_entered.bind(button))
		if not button.mouse_exited.is_connected(_on_answer_mouse_exited.bind(button)):
			button.mouse_exited.connect(_on_answer_mouse_exited.bind(button))

func _initialize_answer_keymap_labels() -> void :
	for index in range(_answer_keymap_labels.size()):
		var label: Label = _answer_keymap_labels[index]
		label.text = ANSWER_KEYMAP_TEXTS[index] if index < ANSWER_KEYMAP_TEXTS.size() else ""
		label.visible = not _is_mobile_platform()

func _initialize_yesno_keymap_labels() -> void :
	yes_keymap.text = YES_KEYMAP_TEXT
	no_keymap.text = NO_KEYMAP_TEXT
	_update_yesno_keymap_visibility()

func _connect_ask_buttons() -> void :
	if not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)

func _initialize_pause_ui() -> void :
	game_pause_menu.visible = false
	game_pause_button.disabled = true

func _connect_pause_buttons() -> void :
	if not game_pause_button.pressed.is_connected(_toggle_game_pause):
		game_pause_button.pressed.connect(_toggle_game_pause)
	if not game_resume_button.pressed.is_connected(_toggle_game_pause):
		game_resume_button.pressed.connect(_toggle_game_pause)

func _initialize_debug_ui() -> void :
	_debug_control_buttons = [
		debug_timer_0, 
		debug_timer_10, 
		debug_timer_25, 
		debug_timer_45, 
		debug_lv_1, 
		debug_lv_2, 
		debug_lv_3, 
		debug_lv_max, 
		debug_ignore_answer, 
	]
	debug_panel.visible = GlobalVar.debug_mode_enabled
	_debug_ignore_answer_enabled = false
	_update_debug_ignore_answer_color()
	_update_debug_controls_state()

func _connect_debug_buttons() -> void :
	var timer_0_callable: = _on_debug_timer_pressed.bind(0)
	var timer_10_callable: = _on_debug_timer_pressed.bind(10)
	var timer_25_callable: = _on_debug_timer_pressed.bind(25)
	var timer_45_callable: = _on_debug_timer_pressed.bind(45)
	var gauge_lv_1_callable: = _on_debug_gauge_pressed.bind(DEBUG_GAUGE_LEVEL_1_RATIO)
	var gauge_lv_2_callable: = _on_debug_gauge_pressed.bind(DEBUG_GAUGE_LEVEL_2_RATIO)
	var gauge_lv_3_callable: = _on_debug_gauge_pressed.bind(DEBUG_GAUGE_LEVEL_3_RATIO)
	var gauge_max_callable: = _on_debug_gauge_pressed.bind(DEBUG_GAUGE_ALMOST_MAX_RATIO)

	if not debug_timer_0.pressed.is_connected(timer_0_callable):
		debug_timer_0.pressed.connect(timer_0_callable)
	if not debug_timer_10.pressed.is_connected(timer_10_callable):
		debug_timer_10.pressed.connect(timer_10_callable)
	if not debug_timer_25.pressed.is_connected(timer_25_callable):
		debug_timer_25.pressed.connect(timer_25_callable)
	if not debug_timer_45.pressed.is_connected(timer_45_callable):
		debug_timer_45.pressed.connect(timer_45_callable)
	if not debug_lv_1.pressed.is_connected(gauge_lv_1_callable):
		debug_lv_1.pressed.connect(gauge_lv_1_callable)
	if not debug_lv_2.pressed.is_connected(gauge_lv_2_callable):
		debug_lv_2.pressed.connect(gauge_lv_2_callable)
	if not debug_lv_3.pressed.is_connected(gauge_lv_3_callable):
		debug_lv_3.pressed.connect(gauge_lv_3_callable)
	if not debug_lv_max.pressed.is_connected(gauge_max_callable):
		debug_lv_max.pressed.connect(gauge_max_callable)
	if not debug_ignore_answer.pressed.is_connected(_on_debug_ignore_answer_pressed):
		debug_ignore_answer.pressed.connect(_on_debug_ignore_answer_pressed)

func _on_debug_timer_pressed(seconds: int) -> void :
	if not _can_use_debug_controls():
		return

	_remaining_time = DEBUG_ASK_PASSED_REMAINING_TIME if seconds == 25 else clampf(float(seconds), 0.0, float(MAX_TIME))
	_update_timer_display()

	if seconds == 0:
		_start_ending(1 if _is_gauge_low_or_medium() else 2)
		return

	if seconds == 25:
		_has_ask_sequence_started = false
		_has_clicked_no = false
		_start_ask_sequence()

func _on_debug_gauge_pressed(ratio: float) -> void :
	if not _can_use_debug_controls():
		return

	_gauge_ratio = clampf(ratio, 0.0, 1.0)
	_update_gauge_display(true)

func _on_debug_ignore_answer_pressed() -> void :
	if not _can_use_debug_controls():
		return

	_debug_ignore_answer_enabled = not _debug_ignore_answer_enabled
	_update_debug_ignore_answer_color()

func _update_debug_ignore_answer_color() -> void :
	var color: Color = DEBUG_TOGGLE_ACTIVE_COLOR if _debug_ignore_answer_enabled else DEBUG_TOGGLE_INACTIVE_COLOR
	for color_name in [
		&"font_color", 
		&"font_hover_color", 
		&"font_pressed_color", 
		&"font_hover_pressed_color", 
		&"font_focus_color", 
		&"font_disabled_color", 
	]:
		debug_ignore_answer.add_theme_color_override(color_name, color)

func _can_use_debug_controls() -> bool:
	return (
		debug_panel.visible
		and _is_game_active
		and _game_phase == GamePhase.QUIZ
		and not _is_quiz_transitioning
		and not _is_ending_started
		and not _is_ending_transition_started
	)

func _update_debug_controls_state() -> void :
	var is_enabled: bool = _can_use_debug_controls()
	for button in _debug_control_buttons:
		button.disabled = not is_enabled
		button.modulate.a = DEBUG_CONTROL_ENABLED_ALPHA if is_enabled else DEBUG_CONTROL_DISABLED_ALPHA

func _move_start_ui_outside_viewport() -> void :
	var viewport_width: float = get_viewport_rect().size.x
	var viewport_height: float = get_viewport_rect().size.y
	var gauge_offset_x: float = viewport_width + maxf(gauge.size.x, 1.0)
	var timer_offset_y: float = viewport_height + maxf(timer_gauge.size.y, 1.0)
	var pause_button_offset_x: float = viewport_width + maxf(game_pause_button.size.x, 1.0)
	gauge.position = Vector2(_gauge_landing_position.x + gauge_offset_x, _gauge_landing_position.y)
	timer_gauge.position = Vector2(_timer_landing_position.x, _timer_landing_position.y - timer_offset_y)
	game_pause_button.position = Vector2(_pause_button_landing_position.x - pause_button_offset_x, _pause_button_landing_position.y)
	_move_answer_buttons_to_bottom(false)

func _get_yesno_outside_position() -> Vector2:
	var viewport_height: float = get_viewport_rect().size.y
	var offset_y: float = viewport_height + maxf(yesno_container.size.y, 1.0)
	return Vector2(_yesno_landing_position.x, _yesno_landing_position.y + offset_y)

func _run_game_start_sequence() -> void :
	await get_tree().process_frame
	_move_start_ui_outside_viewport()

	var startup_wait: float = maxf(GlobalVar.last_transition_duration, 0.0) + GAME_START_POST_TRANSITION_WAIT_TIME
	if startup_wait > 0.0:
		await get_tree().create_timer(startup_wait).timeout

	_play_game_bgm()
	var intro_tween: Tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.tween_property(gauge, "position", _gauge_landing_position, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(timer_gauge, "position", _timer_landing_position, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(game_pause_button, "position", _pause_button_landing_position, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(quiz_question_panel, "modulate:a", 1.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await intro_tween.finished

	var has_quiz: bool = _prepare_next_quiz()
	_start_answer_buttons_in_animation()
	var answer_tween: Tween = create_tween()
	answer_tween.set_parallel(true)
	answer_tween.tween_property(quiz_label, "modulate:a", 1.0, QUIZ_LABELS_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await answer_tween.finished
	_finish_answer_buttons_in_animation()

	_set_answer_buttons_enabled(has_quiz)
	_game_phase = GamePhase.QUIZ
	_is_game_active = true
	game_pause_button.disabled = false
	_update_debug_controls_state()

func _play_game_bgm() -> void :
	if bgm == null:
		return

	AudioManager.play_any_bgm(bgm)

func _toggle_game_pause() -> void :
	if not _can_toggle_game_pause():
		return

	_set_game_paused( not _is_game_paused)

func _can_toggle_game_pause() -> bool:
	return _is_game_active and not _is_ending_started and not _is_ending_transition_started

func _set_game_paused(is_paused: bool) -> void :
	if _is_game_paused == is_paused:
		return

	_is_game_paused = is_paused
	game_pause_menu.visible = is_paused
	game_pause_button.disabled = is_paused

	if is_paused:
		if game_pause_menu.has_method("initialize_pause_panel"):
			game_pause_menu.call("initialize_pause_panel")
		_set_answer_buttons_enabled(false)
		_set_yesno_buttons_enabled(false)
		_set_sfx_players_paused(true)
		_set_game_animation_tweens_paused(true)
	else:
		_set_sfx_players_paused(false)
		_set_game_animation_tweens_paused(false)
		game_pause_button.disabled = false
		_restore_interaction_after_pause()

func _restore_interaction_after_pause() -> void :
	if not _is_game_active or _is_ending_started:
		return

	match _game_phase:
		GamePhase.QUIZ:
			if _is_quiz_transitioning:
				return
			var has_quiz: bool = _prepare_next_quiz()
			quiz_label.modulate.a = 1.0
			_finish_answer_buttons_in_animation()
			_set_answer_buttons_enabled(has_quiz)
		GamePhase.ASK_WAITING:
			_set_yesno_buttons_enabled(true)

func _set_sfx_players_paused(is_paused: bool) -> void :
	if not is_paused:
		for player in _paused_sfx_players:
			if is_instance_valid(player):
				player.stream_paused = false
		_paused_sfx_players.clear()
		return

	_paused_sfx_players.clear()
	for child in AudioManager.get_children():
		if child is AudioStreamPlayer:
			var player: = child as AudioStreamPlayer
			if player.bus == "SFX" and player.playing and not player.stream_paused:
				player.stream_paused = is_paused
				_paused_sfx_players.append(player)

func _set_game_animation_tweens_paused(is_paused: bool) -> void :
	_set_tween_paused(_answer_button_tween, is_paused)
	_set_tween_paused(_gauge_alert_tween, is_paused)
	_set_tween_paused(_breathe_effect_tween, is_paused)
	_set_tween_paused(_result_indicator_tween, is_paused)

	for tween_list in _gas_effect_tweens.values():
		if not (tween_list is Array):
			continue
		for tween in tween_list:
			if tween is Tween:
				_set_tween_paused(tween as Tween, is_paused)

func _set_tween_paused(tween: Tween, is_paused: bool) -> void :
	if tween == null or not tween.is_valid():
		return

	if is_paused:
		tween.pause()
	else:
		tween.play()

func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		_toggle_game_pause()
		get_viewport().set_input_as_handled()
		return

	if _is_game_paused:
		return

	if _handle_yesno_key_input(event):
		get_viewport().set_input_as_handled()
		return

	if _handle_answer_key_input(event):
		get_viewport().set_input_as_handled()
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if _can_click_skip_no_response_wait:
		_is_no_response_wait_skipped = true
		get_viewport().set_input_as_handled()
		return

	if not _can_click_to_ending_transition or _is_ending_transition_started:
		return

	get_viewport().set_input_as_handled()
	_transition_to_ending_cutscene()

func _load_quiz_data() -> void :
	_quiz_entries.clear()
	_quiz_bag.clear()

	_quiz_difficulty_index = clampi(int(SaveManager.config.get_value("Settings", "difficulty_index", GlobalVar.difficulty_index)), 0, VERY_EASY_DIFFICULTY_INDEX)
	if _is_very_easy_difficulty():
		return

	var path: String = QUIZ_CSV_PATH_FORMAT % _quiz_difficulty_index
	if not FileAccess.file_exists(path):
		push_warning("MiniGame: Quiz CSV not found: %s" % path)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("MiniGame: Could not open quiz CSV: %s" % path)
		return

	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 5:
			continue

		var quiz_text: String = row[0].strip_edges()
		var answer_text: String = row[1].strip_edges()
		var wrong_answers: Array[String] = [
			row[2].strip_edges(), 
			row[3].strip_edges(), 
			row[4].strip_edges(), 
		]

		if quiz_text == "" or answer_text == "":
			continue

		_quiz_entries.append({
			"quiz": quiz_text, 
			"answer": answer_text, 
			"wrong": wrong_answers, 
		})

func _prepare_next_quiz() -> bool:
	if _is_very_easy_difficulty():
		return _prepare_very_easy_quiz()

	var quiz_entry: Dictionary = _pop_next_quiz()
	if quiz_entry.is_empty():
		quiz_label.text = ""
		_set_answer_labels([])
		return false

	quiz_label.text = "%s%s" % [String(quiz_entry["quiz"]), QUIZ_PROBLEM_SUFFIX]

	var options: Array[Dictionary] = [
		{"text": String(quiz_entry["answer"]), "is_correct": true}, 
	]

	var wrong_answers: Array = quiz_entry["wrong"]
	for wrong_answer in wrong_answers:
		options.append({"text": String(wrong_answer), "is_correct": false})

	options.shuffle()
	_set_answer_labels(options)
	return true

func _prepare_very_easy_quiz() -> bool:
	quiz_label.text = "%s%s" % [VERY_EASY_QUIZ_TEXT, QUIZ_PROBLEM_SUFFIX]

	_set_answer_labels([
		{"text": "", "is_correct": false}, 
		{"text": VERY_EASY_CORRECT_ANSWER, "is_correct": true}, 
		{"text": VERY_EASY_WRONG_ANSWER, "is_correct": false}, 
		{"text": "", "is_correct": false}, 
	])
	_apply_very_easy_answer_state()
	return true

func _pop_next_quiz() -> Dictionary:
	if _quiz_bag.is_empty():
		_quiz_bag = _quiz_entries.duplicate(true)
		_quiz_bag.shuffle()

	if _quiz_bag.is_empty():
		return {}

	return _quiz_bag.pop_front()

func _set_answer_labels(options: Array) -> void :
	for index in range(_answer_buttons.size()):
		var button: TextureButton = _answer_buttons[index]
		var label: Label = button.get_node("Label") as Label

		if index >= options.size():
			label.text = ""
			button.set_meta("is_correct", false)
			continue

		var option_data: Dictionary = options[index]
		var is_correct: bool = bool(option_data.get("is_correct", false))
		label.text = String(option_data.get("text", ""))
		button.set_meta("is_correct", is_correct)

	_apply_very_easy_answer_state()

func _set_answer_buttons_enabled(is_enabled: bool, should_reset_hover_position: bool = true) -> void :
	if not is_enabled and should_reset_hover_position:
		_reset_answer_button_hover_positions()

	for index in range(_answer_buttons.size()):
		var button: TextureButton = _answer_buttons[index]
		button.disabled = not is_enabled or _is_very_easy_disabled_answer_index(index)
		button.button_pressed = false
		button.release_focus()

	_apply_very_easy_answer_state()

func _apply_very_easy_answer_state() -> void :
	if not _is_very_easy_difficulty() or _answer_buttons.size() < 4:
		return

	for index in range(_answer_buttons.size()):
		var button: TextureButton = _answer_buttons[index]
		var keymap_label: Label = _answer_keymap_labels[index] if index < _answer_keymap_labels.size() else null
		if not _is_very_easy_disabled_answer_index(index):
			if keymap_label:
				keymap_label.visible = not _is_mobile_platform()
			if button.visible:
				button.modulate.a = 1.0
			continue

		var label: Label = button.get_node("Label") as Label
		label.text = ""
		if keymap_label:
			keymap_label.visible = false
		button.set_meta("is_correct", false)
		button.disabled = true
		button.button_pressed = false
		button.release_focus()
		if button.visible:
			button.modulate.a = VERY_EASY_DISABLED_ANSWER_ALPHA

func _is_very_easy_difficulty() -> bool:
	return _quiz_difficulty_index == VERY_EASY_DIFFICULTY_INDEX

func _is_very_easy_disabled_answer_index(index: int) -> bool:
	return _is_very_easy_difficulty() and (index == 0 or index == 3)

func _cache_answer_button_landing_positions() -> void :
	_answer_button_landing_positions.clear()
	for button in _answer_buttons:
		_answer_button_landing_positions[button] = button.position

func _move_answer_buttons_to_bottom(_is_visible: bool) -> void :
	_kill_answer_button_hover_tweens()
	for button in _answer_buttons:
		button.visible = _is_visible
		button.modulate.a = 1.0 if _is_visible else 0.0
		button.position = _get_answer_button_bottom_position(button)

func _get_answer_button_bottom_position(button: TextureButton) -> Vector2:
	var landing_position: Vector2 = _get_answer_button_landing_position(button)
	return Vector2(landing_position.x, landing_position.y + ANSWER_BUTTON_FLY_DOWN_DISTANCE)

func _get_answer_button_upper_position(button: TextureButton) -> Vector2:
	var landing_position: Vector2 = _get_answer_button_landing_position(button)
	return Vector2(landing_position.x, landing_position.y - ANSWER_BUTTON_FLY_UP_DISTANCE)

func _get_answer_button_landing_position(button: TextureButton) -> Vector2:
	var landing_position: Variant = _answer_button_landing_positions.get(button, button.position)
	if landing_position is Vector2:
		return landing_position
	return button.position

func _start_answer_buttons_in_animation() -> void :
	if _is_ending_started:
		_hide_answer_buttons_immediate()
		return

	_kill_answer_button_tween()
	_kill_answer_button_hover_tweens()
	for index in range(_answer_buttons.size()):
		var button: TextureButton = _answer_buttons[index]
		button.visible = true
		button.modulate.a = VERY_EASY_DISABLED_ANSWER_ALPHA if _is_very_easy_disabled_answer_index(index) else 1.0
		button.position = _get_answer_button_bottom_position(button)

	_answer_button_tween = create_tween()
	_answer_button_tween.set_parallel(true)
	for button in _answer_buttons:
		_answer_button_tween.tween_property(button, "position", _get_answer_button_landing_position(button), ANSWER_BUTTON_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _finish_answer_buttons_in_animation() -> void :
	if _is_ending_started:
		_hide_answer_buttons_immediate()
		return

	for index in range(_answer_buttons.size()):
		var button: TextureButton = _answer_buttons[index]
		button.visible = true
		button.modulate.a = VERY_EASY_DISABLED_ANSWER_ALPHA if _is_very_easy_disabled_answer_index(index) else 1.0
		button.position = _get_answer_button_landing_position(button)

	_apply_very_easy_answer_state()

func _start_answer_buttons_out_animation(selected_button: TextureButton, is_correct: bool) -> void :
	if _is_ending_started:
		_hide_answer_buttons_immediate()
		return

	_kill_answer_button_tween()
	_kill_answer_button_hover_tweens()
	_answer_button_tween = create_tween()
	_answer_button_tween.set_parallel(true)
	for button in _answer_buttons:
		button.visible = true
		var target_position: Vector2 = _get_answer_button_bottom_position(button)
		if is_correct and button == selected_button:
			target_position = _get_answer_button_upper_position(button)
			_answer_button_tween.tween_property(button, "modulate:a", 0.0, ANSWER_BUTTON_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		_answer_button_tween.tween_property(button, "position", target_position, ANSWER_BUTTON_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _finish_answer_buttons_out_animation() -> void :
	for button in _answer_buttons:
		button.visible = false

func _hide_answer_buttons_immediate() -> void :
	_kill_answer_button_tween()
	_kill_answer_button_hover_tweens()
	_set_answer_buttons_enabled(false)
	for button in _answer_buttons:
		button.visible = false
		button.modulate.a = 0.0
		button.button_pressed = false
		button.release_focus()

func _kill_answer_button_tween() -> void :
	if _answer_button_tween != null and _answer_button_tween.is_valid():
		_answer_button_tween.kill()
	_answer_button_tween = null

func _on_answer_mouse_entered(button: TextureButton) -> void :
	if not _can_play_answer_hover_animation(button):
		return

	_tween_answer_button_position(button, _get_answer_button_hover_position(button))

func _on_answer_mouse_exited(button: TextureButton) -> void :
	if not _can_play_answer_hover_animation(button):
		return

	if not _answer_button_landing_positions.has(button):
		return

	_tween_answer_button_position(button, _get_answer_button_landing_position(button))

func _can_play_answer_hover_animation(button: TextureButton) -> bool:
	return (
		not _is_mobile_platform()
		and _is_game_active
		and not _is_game_paused
		and not _is_quiz_transitioning
		and not _is_ending_started
		and _game_phase == GamePhase.QUIZ
		and button.visible
		and not button.disabled
	)

func _get_answer_button_hover_position(button: TextureButton) -> Vector2:
	var landing_position: Vector2 = _get_answer_button_landing_position(button)
	return Vector2(landing_position.x, landing_position.y - ANSWER_BUTTON_HOVER_LIFT_Y)

func _tween_answer_button_position(button: TextureButton, target_position: Vector2) -> void :
	if _answer_button_hover_tweens.has(button):
		var existing_tween: Tween = _answer_button_hover_tweens[button]
		if existing_tween:
			existing_tween.kill()

	var tween: Tween = create_tween()
	_answer_button_hover_tweens[button] = tween
	tween.tween_property(button, "position", target_position, ANSWER_BUTTON_HOVER_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_answer_button_hover_tween_finished.bind(button, tween))

func _on_answer_button_hover_tween_finished(button: TextureButton, tween: Tween) -> void :
	if _answer_button_hover_tweens.get(button) == tween:
		_answer_button_hover_tweens.erase(button)

func _kill_answer_button_hover_tweens() -> void :
	for button in _answer_button_hover_tweens.keys():
		var tween: Tween = _answer_button_hover_tweens[button]
		if tween:
			tween.kill()
	_answer_button_hover_tweens.clear()

func _reset_answer_button_hover_positions() -> void :
	_kill_answer_button_hover_tweens()
	for button in _answer_buttons:
		if button.visible and _answer_button_landing_positions.has(button):
			button.position = _get_answer_button_landing_position(button)

func _on_answer_pressed(button: TextureButton) -> void :
	if not _is_game_active or _is_quiz_transitioning:
		return

	_is_quiz_transitioning = true
	_update_debug_controls_state()
	_kill_answer_button_hover_tweens()
	_set_answer_buttons_enabled(false, false)

	var is_correct: bool = bool(button.get_meta("is_correct", false))
	_apply_quiz_gauge_delta(is_correct)
	if not is_correct:
		_play_sfx_gas_emission_once()
	if _is_ending_started:
		return
	_play_quiz_result_sfx(is_correct)
	if not is_correct:
		_show_wrong_answer_portrait()
	_show_result_indicator(is_correct)
	_refresh_quiz_after_answer(button, is_correct)

func _handle_answer_key_input(event: InputEvent) -> bool:
	if _is_mobile_platform():
		return false
	if _game_phase != GamePhase.QUIZ:
		return false

	for index in range(ANSWER_KEYMAP_ACTIONS.size()):
		if index >= _answer_buttons.size():
			break

		if not event.is_action_pressed(ANSWER_KEYMAP_ACTIONS[index]):
			continue

		var button: TextureButton = _answer_buttons[index]
		if button.disabled or not button.visible:
			return true

		_on_answer_pressed(button)
		return true

	return false

func _handle_yesno_key_input(event: InputEvent) -> bool:
	if _is_mobile_platform() or _game_phase != GamePhase.ASK_WAITING:
		return false

	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false

	var keycode: int = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
	match keycode:
		KEY_Q:
			if not yes_button.disabled and yes_button.visible:
				_on_yes_pressed()
			return true
		KEY_R:
			if not no_button.disabled and no_button.visible:
				_on_no_pressed()
			return true

	return false

func _play_quiz_result_sfx(is_correct: bool) -> void :
	var sound: Resource = sfx_quiz_correct if is_correct else sfx_quiz_wrong
	if sound == null:
		return

	AudioManager.play_any_sfx(sound)

func _apply_quiz_gauge_delta(is_correct: bool) -> void :
	var gauge_delta: float = CORRECT_GAUGE_DELTA if is_correct else WRONG_GAUGE_DELTA
	_gauge_ratio = clampf(_gauge_ratio + gauge_delta, 0.0, 1.0)
	_update_gauge_display(true)
	_check_gauge_max_ending()

func _show_result_indicator(is_correct: bool) -> void :
	if _result_indicator_tween:
		_result_indicator_tween.kill()

	result_indicator.text = RESULT_TEXT_CORRECT if is_correct else RESULT_TEXT_WRONG
	result_indicator.add_theme_color_override("font_color", RESULT_COLOR_CORRECT if is_correct else RESULT_COLOR_WRONG)
	result_indicator.position = _result_indicator_base_position
	result_indicator.modulate.a = 1.0
	result_indicator.visible = true

	_result_indicator_tween = create_tween()
	_result_indicator_tween.set_parallel(true)
	_result_indicator_tween.tween_property(result_indicator, "modulate:a", 0.0, RESULT_INDICATOR_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_result_indicator_tween.tween_property(result_indicator, "position:y", _result_indicator_base_position.y - RESULT_INDICATOR_FLY_Y, RESULT_INDICATOR_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_result_indicator_tween.chain().tween_callback(_reset_result_indicator)

func _reset_result_indicator() -> void :
	result_indicator.visible = false
	result_indicator.modulate.a = 0.0
	result_indicator.position = _result_indicator_base_position

func _refresh_quiz_after_answer(selected_button: TextureButton, is_correct: bool) -> void :
	_is_quiz_transitioning = true
	_set_answer_buttons_enabled(false, false)

	_start_answer_buttons_out_animation(selected_button, is_correct)
	await _backspace_quiz_label_text(quiz_label.text)
	_finish_answer_buttons_out_animation()
	if _game_phase != GamePhase.QUIZ or _is_ending_started:
		return

	var has_quiz: bool = _prepare_next_quiz()

	_start_answer_buttons_in_animation()
	await _type_quiz_label_text(quiz_label.text)
	if _game_phase != GamePhase.QUIZ or _is_ending_started:
		_hide_answer_buttons_immediate()
		return
	_finish_answer_buttons_in_animation()

	_set_answer_buttons_enabled(has_quiz)
	_is_quiz_transitioning = false
	_update_debug_controls_state()

func _backspace_quiz_label_text(source_text: String) -> void :
	var step_count: int = max(_get_quiz_refresh_text_step_count(), source_text.length())
	var step_duration: float = QUIZ_REFRESH_TEXT_CHANGE_DURATION * 0.5 / float(step_count)
	for step_index in range(step_count):
		if _game_phase != GamePhase.QUIZ or _is_ending_started:
			return
		var visible_count: int = maxi(source_text.length() - step_index - 1, 0)
		quiz_label.text = source_text.substr(0, visible_count)
		await get_tree().create_timer(step_duration).timeout

func _type_quiz_label_text(target_text: String) -> void :
	quiz_label.text = ""
	quiz_label.modulate.a = 1.0
	var step_count: int = max(_get_quiz_refresh_text_step_count(), target_text.length())
	var step_duration: float = QUIZ_REFRESH_TEXT_CHANGE_DURATION * 0.5 / float(step_count)
	for step_index in range(step_count):
		if _game_phase != GamePhase.QUIZ or _is_ending_started:
			return
		var visible_count: int = mini(step_index + 1, target_text.length())
		quiz_label.text = target_text.substr(0, visible_count)
		await get_tree().create_timer(step_duration).timeout
	quiz_label.text = target_text

func _get_quiz_refresh_text_step_count() -> int:
	return QUIZ_REFRESH_EASY_TEXT_STEPS if _quiz_difficulty_index == 0 or _is_very_easy_difficulty() else QUIZ_REFRESH_NORMAL_HARD_TEXT_STEPS

func _start_ask_sequence() -> void :
	if _has_ask_sequence_started or _is_ending_started:
		return

	_has_ask_sequence_started = true
	_game_phase = GamePhase.ASK_TRANSITION
	_is_gauge_paused = true
	_is_timer_paused = true
	_is_quiz_transitioning = true
	_update_debug_controls_state()
	_set_answer_buttons_enabled(false)
	_set_yesno_buttons_enabled(false)
	result_indicator.visible = false

	var quiz_fade_tween: Tween = create_tween()
	quiz_fade_tween.set_parallel(true)
	quiz_fade_tween.tween_property(quiz_question_panel, "modulate:a", 0.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	quiz_fade_tween.tween_property(quiz_label, "modulate:a", 0.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for button in _answer_buttons:
		quiz_fade_tween.tween_property(button, "modulate:a", 0.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await quiz_fade_tween.finished
	if _is_ending_started:
		return
	for button in _answer_buttons:
		button.visible = false

	_set_char_portrait(CHAR_PORTRAIT_ASKING_QUESTION_PATH)
	_set_ask_label_by_current_gauge()
	ask_container.visible = true
	ask_container.modulate.a = 0.0
	yesno_container.visible = false
	yesno_container.position = _get_yesno_outside_position()

	var ask_fade_tween: Tween = create_tween()
	ask_fade_tween.tween_property(ask_container, "modulate:a", 1.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await ask_fade_tween.finished
	if _is_ending_started:
		return

	await get_tree().create_timer(ASK_YESNO_WAIT_TIME).timeout
	if _is_ending_started:
		return

	_update_yesno_labels_by_current_gauge()
	yesno_container.position = _get_yesno_outside_position()
	yesno_container.visible = true
	_game_phase = GamePhase.ASK_WAITING

	var yesno_tween: Tween = create_tween()
	yesno_tween.tween_property(yesno_container, "position", _yesno_landing_position, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await yesno_tween.finished
	if _is_ending_started:
		return

	_is_gauge_paused = false
	_is_timer_paused = false
	_set_yesno_buttons_enabled(true)
	_is_quiz_transitioning = false

func _set_ask_label_by_current_gauge() -> void :
	var key: String = ASK_TOILET_KEY_FORMAT % _get_gauge_state_variant()
	_set_rich_text_from_key(ask_label, key)

func _update_yesno_labels_by_current_gauge() -> void :
	var variant: int = _get_gauge_state_variant()
	yes_label.text = tr(ASK_ANSWER_YES_KEY_FORMAT % variant)
	no_label.text = tr(ASK_ANSWER_NO_KEY_FORMAT % variant)

func _set_yesno_buttons_enabled(is_enabled: bool) -> void :
	yes_button.visible = true
	yes_button.disabled = not is_enabled or GlobalVar.is_trial_version
	yes_button.modulate.a = 0.2 if GlobalVar.is_trial_version else 1.0
	no_button.disabled = not is_enabled
	_update_yesno_keymap_visibility()

func _update_yesno_keymap_visibility() -> void :
	var should_show_keymap: bool = not _is_mobile_platform()
	yes_keymap.visible = should_show_keymap
	no_keymap.visible = should_show_keymap

func _on_yes_pressed() -> void :
	if _game_phase != GamePhase.ASK_WAITING or _is_ending_started:
		return
	if GlobalVar.is_trial_version:
		return

	var ending_index: int = _get_yes_ending_index()
	_set_char_portrait(_get_yes_drop_portrait_path())
	if _debug_ignore_answer_enabled:
		_has_clicked_no = true
		_run_no_response_sequence(GAME_END_KEY_FORMAT % ending_index)
		return
	_start_ending(ending_index)

func _on_no_pressed() -> void :
	if _game_phase != GamePhase.ASK_WAITING or _is_ending_started:
		return

	_has_clicked_no = true
	_run_no_response_sequence()

func _run_no_response_sequence(response_key_override: String = "") -> void :
	_game_phase = GamePhase.NO_RESPONSE
	_is_gauge_paused = true
	_is_timer_paused = true
	_is_quiz_transitioning = true
	_update_debug_controls_state()
	if _is_gauge_high():
		_set_char_portrait(CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH)
	_set_yesno_buttons_enabled(false)
	ask_container.visible = false
	ask_container.modulate.a = 0.0
	yesno_container.visible = false

	var response_key: String = response_key_override
	if response_key == "":
		response_key = RESPONSE_NO_KEY_FORMAT % _get_gauge_state_variant()
	var raw_text: String = _set_rich_text_from_key(dialogue_label, response_key)
	ending_diagloauge_box.visible = true
	ending_diagloauge_box.modulate.a = 1.0

	var wait_duration: float = _get_auto_slow_display_duration(dialogue_label, raw_text)
	if wait_duration > 0.0:
		await _wait_no_response_duration(wait_duration)
	if _is_ending_started:
		return

	var fade_out_tween: Tween = create_tween()
	fade_out_tween.tween_property(ending_diagloauge_box, "modulate:a", 0.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_out_tween.finished
	if _is_ending_started:
		return

	ending_diagloauge_box.visible = false
	dialogue_label.text = ""
	_resume_quiz_after_no_response()

func _wait_no_response_duration(duration: float) -> void :
	_can_click_skip_no_response_wait = true
	_is_no_response_wait_skipped = false

	var wait_until_msec: int = Time.get_ticks_msec() + int(duration * 1000.0)
	while not _is_no_response_wait_skipped and Time.get_ticks_msec() < wait_until_msec and not _is_ending_started:
		await get_tree().process_frame

	_can_click_skip_no_response_wait = false
	_is_no_response_wait_skipped = false

func _resume_quiz_after_no_response() -> void :
	_game_phase = GamePhase.QUIZ
	_update_gauge_state_textures(true)
	quiz_question_panel.visible = true
	quiz_question_panel.modulate.a = 0.0
	quiz_label.modulate.a = 0.0
	_move_answer_buttons_to_bottom(false)

	var has_quiz: bool = _prepare_next_quiz()
	var quiz_fade_tween: Tween = create_tween()
	quiz_fade_tween.set_parallel(true)
	quiz_fade_tween.tween_property(quiz_question_panel, "modulate:a", 1.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	quiz_fade_tween.tween_property(quiz_label, "modulate:a", 1.0, GAME_START_UI_FLY_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_start_answer_buttons_in_animation()
	await quiz_fade_tween.finished
	if _is_ending_started:
		_hide_answer_buttons_immediate()
		return
	_finish_answer_buttons_in_animation()

	_set_answer_buttons_enabled(has_quiz)
	_is_quiz_transitioning = false
	_is_gauge_paused = false
	_is_timer_paused = false
	_update_debug_controls_state()

func _check_gauge_max_ending() -> void :
	if _is_ending_started or _gauge_ratio < 1.0:
		return

	if _has_clicked_no:
		_set_char_portrait(CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH)
		_start_ending(8)
	elif _game_phase == GamePhase.ASK_WAITING:
		_set_char_portrait(CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH)
		_start_ending(7)
	elif not _has_ask_sequence_started and _remaining_time >= ASK_TRIGGER_REMAINING_TIME:
		_start_ending(6)

func _start_ending(ending_index: int) -> void :
	if _is_ending_started:
		return

	_ending_index = _resolve_trial_ending_index(ending_index)
	_is_ending_started = true
	if _ending_index == 1:
		_set_char_portrait(CHAR_PORTRAIT_ENDING_1_PATH)
	elif _ending_index in [2, 6, 8]:
		_set_char_portrait(CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH)
	_game_phase = GamePhase.ENDING
	_is_game_active = false
	_is_gauge_paused = true
	_is_timer_paused = true
	_is_quiz_transitioning = true
	_update_debug_controls_state()
	_hide_answer_buttons_immediate()
	_set_yesno_buttons_enabled(false)

	if _result_indicator_tween:
		_result_indicator_tween.kill()
	result_indicator.visible = false
	quiz_question_panel.visible = false
	ask_container.visible = false
	yesno_container.visible = false

	_unlock_ending_with_bonus(_ending_index)
	var ending_key: String = GAME_END_KEY_FORMAT % _ending_index
	_set_rich_text_from_key(dialogue_label, ending_key)
	ending_diagloauge_box.visible = true
	ending_diagloauge_box.modulate.a = 1.0
	_schedule_ending_cutscene_transition()

func _resolve_trial_ending_index(ending_index: int) -> int:
	var resolved_index: int = clampi(ending_index, 1, 8)
	if GlobalVar.is_trial_version and resolved_index != 1:
		return 2
	return resolved_index

func _unlock_ending_with_bonus(ending_index: int) -> void :
	SaveManager.unlock_ending(ending_index)

func _schedule_ending_cutscene_transition() -> void :
	var unskippable_wait_time: float = minf(ENDING_CUTSCENE_UNSKIPPABLE_WAIT_TIME, ENDING_CUTSCENE_WAIT_TIME)
	if unskippable_wait_time > 0.0:
		await get_tree().create_timer(unskippable_wait_time).timeout
		if _is_ending_transition_started:
			return

	_can_click_to_ending_transition = true
	var remaining_wait_time: float = maxf(ENDING_CUTSCENE_WAIT_TIME - unskippable_wait_time, 0.0)
	if remaining_wait_time > 0.0:
		await get_tree().create_timer(remaining_wait_time).timeout
	_transition_to_ending_cutscene()

func _transition_to_ending_cutscene() -> void :
	if _is_ending_transition_started or _ending_index <= 0:
		return

	_is_ending_transition_started = true
	_can_click_to_ending_transition = false
	GlobalVar.play_cutscene_id = CUTSCENE_ID_FORMAT % _ending_index
	GlobalVar.chained_cutscene_id = ""
	GlobalVar.auto_transition_after_cutscene = MAIN_TREE_SCENE
	GlobalVar.open_replay_panel_on_main = false
	GlobalVar.last_transition_type = CUTSCENE_TRANSITION_TYPE
	GlobalVar.last_transition_duration = ENDING_CUTSCENE_TRANSITION_DURATION

	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(CUTSCENE_PLAYER_SCENE, CUTSCENE_TRANSITION_TYPE, ENDING_CUTSCENE_TRANSITION_DURATION)
	else:
		get_tree().change_scene_to_file(CUTSCENE_PLAYER_SCENE)

func _set_rich_text_from_key(label: RichTextLabel, key: String) -> String:
	var raw_text: String = tr(key)
	label.text = _format_game_rich_text(raw_text)
	return raw_text

func _format_game_rich_text(raw_text: String) -> String:
	var text: String = _expand_game_rich_text_replacements(raw_text)
	return _rx_game_wait_tag.sub(text, "", true)

func _expand_game_rich_text_replacements(raw_text: String) -> String:
	var text: String = raw_text
	for key in GAME_RICH_TEXT_REPLACEMENTS.keys():
		text = text.replace(key, GAME_RICH_TEXT_REPLACEMENTS[key])
	return text

func _get_auto_slow_display_duration(label: RichTextLabel, raw_text: String) -> float:
	var locale: String = TranslationServer.get_locale().left(2)
	if not DialogueManager.AUTO_WAIT_MULTIPLIERS.has(locale):
		locale = "en"

	var multiplier: float = float(DialogueManager.AUTO_WAIT_MULTIPLIERS[locale][RESPONSE_NO_AUTO_MODE_INDEX])
	var min_wait: float = float(DialogueManager.AUTO_MIN_WAIT[RESPONSE_NO_AUTO_MODE_INDEX])
	var char_count: int = _get_visible_text_length(label.text)
	return maxf(min_wait, float(char_count) * multiplier) + _get_wait_tag_total(raw_text)

func _get_wait_tag_total(raw_text: String) -> float:
	var text: String = _expand_game_rich_text_replacements(raw_text)
	var total: float = 0.0
	for match_result in _rx_game_wait_tag.search_all(text):
		var wait_value: String = match_result.get_string(2)
		total += float(wait_value) if wait_value != "" else 0.5
	return total

func _get_visible_text_length(text: String) -> int:
	return _rx_game_bbcode_strip.sub(text, "", true).length()

func _is_gauge_low() -> bool:
	return _get_gauge_state() == GaugeState.LOW

func _is_gauge_medium() -> bool:
	return _get_gauge_state() == GaugeState.MEDIUM

func _is_gauge_high() -> bool:
	return _get_gauge_state() == GaugeState.HIGH

func _is_gauge_low_or_medium() -> bool:
	return not _is_gauge_high()

func _get_gauge_state_variant() -> int:
	match _get_gauge_state():
		GaugeState.LOW:
			return 1
		GaugeState.MEDIUM:
			return 2
		GaugeState.HIGH:
			return 3
	return 1

func _get_gauge_state() -> int:
	if _gauge_ratio >= GAUGE_THRESHOLD_2:
		return GaugeState.HIGH
	if _gauge_ratio >= GAUGE_THRESHOLD_1:
		return GaugeState.MEDIUM
	return GaugeState.LOW

func _get_yes_ending_index() -> int:
	match _get_gauge_state():
		GaugeState.LOW:
			return 3
		GaugeState.MEDIUM:
			return 4
		GaugeState.HIGH:
			return 5
	return 3

func _get_yes_drop_portrait_path() -> String:
	match _get_gauge_state():
		GaugeState.LOW:
			return CHAR_PORTRAIT_LOW_GAUGE_DROP_PATH
		GaugeState.MEDIUM:
			return CHAR_PORTRAIT_MEDIUM_GAUGE_DROP_PATH
		GaugeState.HIGH:
			return CHAR_PORTRAIT_HIGH_GAUGE_DROP_PATH
	return CHAR_PORTRAIT_LOW_GAUGE_DROP_PATH

func _preload_runtime_textures() -> void :
	for path in RUNTIME_TEXTURE_PATHS:
		_get_cached_texture(String(path))

func _get_cached_texture(path: String) -> Texture2D:
	if path == "":
		return null

	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_warning("MiniGame: Could not load texture: %s" % path)
		return null

	_texture_cache[path] = texture
	return texture

func _set_char_portrait(path: String) -> void :
	var texture: Texture2D = _get_cached_texture(path)
	if texture == null or char_portrait.texture == texture:
		return

	char_portrait.texture = texture

func _show_wrong_answer_portrait() -> void :
	_portrait_override_until_msec = Time.get_ticks_msec() + int(WRONG_ANSWER_PORTRAIT_DURATION * 1000.0)
	_set_char_portrait(CHAR_PORTRAIT_WRONG_ANSWER_PATH)
	_restore_portrait_after_wrong_answer(_portrait_override_until_msec)

func _restore_portrait_after_wrong_answer(override_until_msec: int) -> void :
	await get_tree().create_timer(WRONG_ANSWER_PORTRAIT_DURATION).timeout
	if _portrait_override_until_msec != override_until_msec:
		return
	if _game_phase != GamePhase.QUIZ or _is_ending_started:
		return

	_portrait_override_until_msec = 0
	_update_gauge_state_textures(true)

func _can_gauge_update_portrait() -> bool:
	if _portrait_override_until_msec > Time.get_ticks_msec():
		return false

	return _game_phase == GamePhase.STARTUP or _game_phase == GamePhase.QUIZ or _game_phase == GamePhase.ASK_WAITING

func _apply_locale_layout() -> void :
	var language: = TranslationServer.get_locale().get_slice("_", 0)
	var is_flipped: = language in FLIPPED_DIRECTION_LOCALES

	_is_layout_flipped = is_flipped
	_background_direction = 1.0 if is_flipped else -1.0
	char_portrait.flip_h = is_flipped
	car_seat.flip_h = is_flipped
	car_seat_front.flip_h = is_flipped
	_set_texture_rect_children_flip(gas_effects, is_flipped)
	_set_texture_rect_children_flip(breathe_effects, is_flipped)
	_apply_effect_group_layout(gas_effects, _gas_effect_initial_rects, true)
	_apply_effect_group_layout(breathe_effects, _breathe_effect_initial_rects, false)
	_apply_text_label_y_offsets(language)

	_reset_background_scroll_positions()

func _apply_text_label_y_offsets(language: String) -> void :
	ask_label.position = Vector2(_ask_label_base_position.x, _ask_label_base_position.y + GlobalVar.get_label_text_y_offset(ask_label, language))
	dialogue_label.position = Vector2(_dialogue_label_base_position.x, _dialogue_label_base_position.y + GlobalVar.get_label_text_y_offset(dialogue_label, language))

func _set_texture_rect_children_flip(parent: Node, is_flipped: bool) -> void :
	for child in parent.get_children():
		if child is TextureRect:
			var texture_rect: = child as TextureRect
			texture_rect.flip_h = is_flipped

func _apply_effect_group_layout(parent: Control, initial_rects: Dictionary, skip_active_gas_effects: bool) -> void :
	for effect in initial_rects.keys():
		if not (effect is TextureRect):
			continue

		if skip_active_gas_effects and _gas_effect_tweens.has(effect):
			continue

		var texture_rect: = effect as TextureRect
		var rect: Dictionary = _get_effect_layout_rect(parent, initial_rects[effect])
		texture_rect.position = rect["position"]
		texture_rect.size = rect["size"]

func _get_effect_layout_rect(parent: Control, initial_rect: Dictionary) -> Dictionary:
	var _position: Vector2 = initial_rect["position"]
	var _size: Vector2 = initial_rect["size"]

	if _is_layout_flipped:
		_position.x = parent.size.x - _position.x - _size.x

	return {
		"position": _position, 
		"size": _size, 
	}

func _reset_background_scroll_positions() -> void :
	bg_far.position.x = _bg_far_neutral_x
	bg_med.position.x = _get_background_loop_start_x(_bg_med_neutral_x)
	bg_near.position.x = _get_background_loop_start_x(_bg_near_neutral_x)

func _get_background_loop_start_x(neutral_x: float, direction: float = _background_direction) -> float:
	return neutral_x - GlobalVar.BG_LOOP_WIDTH if direction > 0.0 else neutral_x

func _update_background_scroll(delta: float) -> void :
	_scroll_background_layer(bg_far, _bg_far_neutral_x, GlobalVar.BG_FAR_SCROLL_SPEED, delta, - _background_direction)
	_scroll_background_layer(bg_med, _bg_med_neutral_x, GlobalVar.BG_MED_SCROLL_SPEED, delta)
	_scroll_background_layer(bg_near, _bg_near_neutral_x, GlobalVar.BG_NEAR_SCROLL_SPEED, delta)

func _scroll_background_layer(layer: TextureRect, neutral_x: float, speed: float, delta: float, direction: float = _background_direction) -> void :
	layer.position.x += speed * direction * delta

	if direction < 0.0 and layer.position.x <= neutral_x - GlobalVar.BG_LOOP_WIDTH:
		layer.position.x = neutral_x
	elif direction > 0.0 and layer.position.x >= neutral_x:
		layer.position.x = neutral_x - GlobalVar.BG_LOOP_WIDTH

func _update_car_shake(delta: float) -> void :
	_car_shake_timer += delta

	if _car_shake_timer >= _car_shake_next_interval:
		_car_shake_timer = 0.0
		_car_shake_next_interval = randf_range(CAR_SHAKE_INTERVAL_MIN, CAR_SHAKE_INTERVAL_MAX)
		_car_shake_target_y = _get_random_shake_offset_y()

	_car_shake_current_y = lerpf(_car_shake_current_y, _car_shake_target_y, clampf(delta * CAR_SHAKE_SMOOTH_SPEED, 0.0, 1.0))
	var shake_y: = roundf(_car_shake_current_y)
	car_seat.position = Vector2(_car_seat_base_position.x, _car_seat_base_position.y + shake_y)
	char_portrait.position = Vector2(_char_portrait_base_position.x, _char_portrait_base_position.y + shake_y)

func _get_random_shake_offset_y() -> float:
	var stddev: = CAR_SHAKE_MAX_Y * CAR_SHAKE_STDDEV_RATIO
	var magnitude: = minf(absf(randfn(0.0, stddev)), CAR_SHAKE_MAX_Y)
	return - magnitude

func _update_timer(delta: float) -> void :
	if _is_timer_paused:
		return

	if _remaining_time <= 0.0:
		return

	var previous_time: float = _remaining_time
	_remaining_time = maxf(_remaining_time - delta, 0.0)
	_update_timer_display()

	if _remaining_time <= 0.0:
		_start_ending(1 if _is_gauge_low_or_medium() else 2)
		return

	if previous_time > ASK_TRIGGER_REMAINING_TIME and _remaining_time <= ASK_TRIGGER_REMAINING_TIME:
		_start_ask_sequence()

func _update_timer_display() -> void :
	remaining_time.text = "%d" % ceili(_remaining_time)
	timer_gauge.value = clampf(_remaining_time, float(timer_gauge.min_value), float(timer_gauge.max_value))
	var timer_range: float = maxf(float(timer_gauge.max_value) - float(timer_gauge.min_value), 1.0)
	var elapsed_ratio: float = clampf((float(timer_gauge.max_value) - _remaining_time) / timer_range, 0.0, 1.0)
	timer_indicator.rotation_degrees = elapsed_ratio * TIMER_INDICATOR_FULL_ROTATION_DEGREES

func _update_timer_indicator_pivot() -> void :
	timer_indicator.pivot_offset = timer_gauge.size * 0.5 - timer_indicator.position

func _update_gauge(delta: float) -> void :
	if _is_gauge_paused or _gauge_ratio >= 1.0:
		return

	_gauge_ratio = minf(_gauge_ratio + delta / float(GAUGE_FILL_TIME), 1.0)
	_update_gauge_display()
	_check_gauge_max_ending()

func _update_gauge_display(force_texture_update: bool = false) -> void :
	_update_gauge_value()
	_update_gauge_state_textures(force_texture_update)

func _update_gauge_value() -> void :
	if _gauge_ratio <= 0.0:
		gauge.value = gauge.min_value
		return

	var visual_start: float = float(GAUGE_TEXTURE_TRANSPARENT_MARGIN_BOTTOM) / float(GAUGE_TEXTURE_HEIGHT)
	var visual_end: float = float(GAUGE_TEXTURE_HEIGHT - GAUGE_TEXTURE_TRANSPARENT_MARGIN_TOP) / float(GAUGE_TEXTURE_HEIGHT)
	var vertical_fill_ratio: float = lerpf(visual_start, visual_end, clampf(_gauge_ratio, 0.0, 1.0))
	gauge.value = lerpf(float(gauge.min_value), float(gauge.max_value), vertical_fill_ratio)

func _update_gauge_state_textures(force_update: bool = false) -> void :
	var next_gauge_state: int = _get_gauge_state()

	if not force_update and next_gauge_state == _gauge_state:
		return

	_gauge_state = next_gauge_state

	match _gauge_state:
		GaugeState.LOW:
			_set_gauge_textures(GAUGE_TEXTURE_OVER_LOW, GAUGE_TEXTURE_PROGRESS_LOW)
			_stop_gauge_alert_loop()
			if _can_gauge_update_portrait():
				_set_char_portrait(CHAR_PORTRAIT_LOW_GAUGE_PATH)
		GaugeState.MEDIUM:
			_set_gauge_textures(GAUGE_TEXTURE_OVER_MEDIUM, GAUGE_TEXTURE_PROGRESS_MEDIUM)
			_start_gauge_alert_loop(GAUGE_ALERT_MEDIUM_FADE_CYCLE_DURATION, GAUGE_ALERT_MEDIUM_MAX_ALPHA)
			if _can_gauge_update_portrait():
				_set_char_portrait(CHAR_PORTRAIT_MEDIUM_GAUGE_PATH)
		GaugeState.HIGH:
			_set_gauge_textures(GAUGE_TEXTURE_OVER_HIGH, GAUGE_TEXTURE_PROGRESS_HIGH)
			_start_gauge_alert_loop(GAUGE_ALERT_FADE_CYCLE_DURATION, GAUGE_ALERT_HIGH_MAX_ALPHA)
			if _can_gauge_update_portrait():
				_set_char_portrait(CHAR_PORTRAIT_HIGH_GAUGE_PATH)

func _set_gauge_textures(over_path: String, progress_path: String) -> void :
	var over_texture: Texture2D = _get_cached_texture(over_path)
	var progress_texture: Texture2D = _get_cached_texture(progress_path)

	if over_texture != null and gauge.texture_over != over_texture:
		gauge.texture_over = over_texture
	if progress_texture != null and gauge.texture_progress != progress_texture:
		gauge.texture_progress = progress_texture

func _initialize_gauge_alert() -> void :
	if _gauge_alert_tween != null and _gauge_alert_tween.is_valid():
		_gauge_alert_tween.kill()
	_gauge_alert_tween = null
	_is_gauge_alert_looping = false
	_gauge_alert_cycle_duration = 0.0
	_gauge_alert_max_alpha = 0.0
	gauge_alert.visible = false
	gauge_alert.modulate.a = 0.0

func _start_gauge_alert_loop(cycle_duration: float, max_alpha: float) -> void :
	var clamped_cycle_duration: float = maxf(cycle_duration, 0.01)
	var clamped_max_alpha: float = clampf(max_alpha, 0.0, 1.0)
	var is_same_alert_loop: bool = (
		_is_gauge_alert_looping
		and _gauge_alert_tween != null
		and _gauge_alert_tween.is_valid()
		and is_equal_approx(_gauge_alert_cycle_duration, clamped_cycle_duration)
		and is_equal_approx(_gauge_alert_max_alpha, clamped_max_alpha)
	)
	if is_same_alert_loop:
		return

	if _gauge_alert_tween != null and _gauge_alert_tween.is_valid():
		_gauge_alert_tween.kill()

	_is_gauge_alert_looping = true
	_gauge_alert_cycle_duration = clamped_cycle_duration
	_gauge_alert_max_alpha = clamped_max_alpha
	gauge_alert.visible = true
	_gauge_alert_tween = create_tween()
	_gauge_alert_tween.set_loops()
	_gauge_alert_tween.tween_property(gauge_alert, "modulate:a", clamped_max_alpha, clamped_cycle_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gauge_alert_tween.tween_property(gauge_alert, "modulate:a", 0.0, clamped_cycle_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_gauge_alert_loop() -> void :
	_is_gauge_alert_looping = false

	if _gauge_alert_tween != null and _gauge_alert_tween.is_valid():
		_gauge_alert_tween.kill()

	if gauge_alert.modulate.a <= 0.0:
		gauge_alert.modulate.a = 0.0
		gauge_alert.visible = false
		_gauge_alert_tween = null
		return

	_gauge_alert_tween = create_tween()
	_gauge_alert_tween.tween_property(gauge_alert, "modulate:a", 0.0, GAUGE_ALERT_FADE_CYCLE_DURATION * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gauge_alert_tween.tween_callback(_finish_gauge_alert_fade_out)

func _finish_gauge_alert_fade_out() -> void :
	if _is_gauge_alert_looping:
		return
	gauge_alert.modulate.a = 0.0
	gauge_alert.visible = false
	_gauge_alert_tween = null
	_gauge_alert_cycle_duration = 0.0
	_gauge_alert_max_alpha = 0.0

func _update_sfx_chara_state_scheduler(delta: float) -> void :
	if sfx_chara_state_list.is_empty():
		return

	_sfx_chara_state_time_until_next -= delta
	if _sfx_chara_state_time_until_next > 0.0:
		return

	var sound: = _pop_next_sfx_chara_state()
	if sound == null:
		_sfx_chara_state_time_until_next = sfx_chara_state_interval_at_empty_gauge
		return

	AudioManager.play_any_sfx(sound)
	_sfx_chara_state_last = sound
	_sfx_chara_state_time_until_next = _get_next_sfx_chara_state_interval(sound)

func _pop_next_sfx_chara_state() -> Resource:
	if _sfx_chara_state_bag.is_empty():
		_refill_sfx_chara_state_bag()

	if _sfx_chara_state_bag.is_empty():
		return null

	_move_non_repeated_sfx_chara_state_to_front()
	return _sfx_chara_state_bag.pop_front()

func _refill_sfx_chara_state_bag() -> void :
	_sfx_chara_state_bag.clear()

	for sound in sfx_chara_state_list:
		if _is_valid_sfx_chara_state(sound):
			_sfx_chara_state_bag.append(sound)

	_sfx_chara_state_bag.shuffle()
	_move_non_repeated_sfx_chara_state_to_front()

func _move_non_repeated_sfx_chara_state_to_front() -> void :
	if _sfx_chara_state_last == null or _sfx_chara_state_bag.size() <= 1:
		return

	if not _is_same_sfx_chara_state(_sfx_chara_state_bag[0], _sfx_chara_state_last):
		return

	for index in range(1, _sfx_chara_state_bag.size()):
		if not _is_same_sfx_chara_state(_sfx_chara_state_bag[index], _sfx_chara_state_last):
			var replacement: = _sfx_chara_state_bag[index]
			_sfx_chara_state_bag[index] = _sfx_chara_state_bag[0]
			_sfx_chara_state_bag[0] = replacement
			return

func _is_valid_sfx_chara_state(sound: Resource) -> bool:
	if sound is SoundData:
		var data: = sound as SoundData
		return data.stream != null

	return sound is AudioStream

func _get_next_sfx_chara_state_interval(sound: Resource) -> float:
	var duration: = _get_sfx_chara_state_duration(sound)
	var post_finish_delay: = lerpf(sfx_chara_state_interval_at_empty_gauge, - sfx_chara_state_overlap_at_full_gauge, clampf(_gauge_ratio, 0.0, 1.0))
	return maxf(duration + post_finish_delay, 0.0)

func _get_sfx_chara_state_duration(sound: Resource) -> float:
	var stream: = _get_sfx_chara_state_stream(sound)
	if stream == null:
		return 0.0

	return stream.get_length()

func _is_same_sfx_chara_state(a: Resource, b: Resource) -> bool:
	if a == b:
		return true

	var stream_a: = _get_sfx_chara_state_stream(a)
	var stream_b: = _get_sfx_chara_state_stream(b)
	if stream_a == null or stream_b == null:
		return false

	if stream_a == stream_b:
		return true

	return not stream_a.resource_path.is_empty() and stream_a.resource_path == stream_b.resource_path

func _get_sfx_chara_state_stream(sound: Resource) -> AudioStream:
	return _get_sfx_resource_stream(sound)

func _update_sfx_gas_emission_scheduler(delta: float) -> void :
	if sfx_gas_emission_list.is_empty():
		return

	var interval: float = _get_sfx_gas_emission_auto_interval()
	if interval <= 0.0:
		_sfx_gas_emission_time_until_next = maxf(_sfx_gas_emission_time_until_next, sfx_gas_emission_interval_medium_gauge)
		return

	_sfx_gas_emission_time_until_next -= delta
	if _sfx_gas_emission_time_until_next > 0.0:
		return

	_play_sfx_gas_emission_once()

func _play_sfx_gas_emission_once() -> void :
	var sound: = _pop_next_sfx_gas_emission()
	if sound == null:
		_sfx_gas_emission_time_until_next = _get_sfx_gas_emission_wait_interval()
		return

	AudioManager.play_any_sfx(sound)
	_play_gas_effect()
	_sfx_gas_emission_last = sound
	_sfx_gas_emission_time_until_next = _get_next_sfx_gas_emission_interval(sound)

func _pop_next_sfx_gas_emission() -> Resource:
	if _sfx_gas_emission_bag.is_empty():
		_refill_sfx_gas_emission_bag()

	if _sfx_gas_emission_bag.is_empty():
		return null

	_move_non_repeated_sfx_gas_emission_to_front()
	return _sfx_gas_emission_bag.pop_front()

func _refill_sfx_gas_emission_bag() -> void :
	_sfx_gas_emission_bag.clear()

	for sound in sfx_gas_emission_list:
		if _is_valid_sfx_gas_emission(sound):
			_sfx_gas_emission_bag.append(sound)

	_sfx_gas_emission_bag.shuffle()
	_move_non_repeated_sfx_gas_emission_to_front()

func _move_non_repeated_sfx_gas_emission_to_front() -> void :
	if _sfx_gas_emission_last == null or _sfx_gas_emission_bag.size() <= 1:
		return

	if not _is_same_sfx_gas_emission(_sfx_gas_emission_bag[0], _sfx_gas_emission_last):
		return

	for index in range(1, _sfx_gas_emission_bag.size()):
		if not _is_same_sfx_gas_emission(_sfx_gas_emission_bag[index], _sfx_gas_emission_last):
			var replacement: = _sfx_gas_emission_bag[index]
			_sfx_gas_emission_bag[index] = _sfx_gas_emission_bag[0]
			_sfx_gas_emission_bag[0] = replacement
			return

func _is_valid_sfx_gas_emission(sound: Resource) -> bool:
	return _is_valid_sfx_resource(sound)

func _get_next_sfx_gas_emission_interval(sound: Resource) -> float:
	var duration: float = _get_sfx_gas_emission_duration(sound)
	return duration + _get_sfx_gas_emission_wait_interval()

func _get_sfx_gas_emission_wait_interval() -> float:
	var interval: float = _get_sfx_gas_emission_auto_interval()
	return interval if interval > 0.0 else maxf(sfx_gas_emission_interval_medium_gauge, 0.0)

func _get_sfx_gas_emission_auto_interval() -> float:
	match _get_gauge_state():
		GaugeState.MEDIUM:
			return maxf(sfx_gas_emission_interval_medium_gauge, 0.0)
		GaugeState.HIGH:
			return maxf(sfx_gas_emission_interval_high_gauge, 0.0)
	return -1.0

func _get_sfx_gas_emission_duration(sound: Resource) -> float:
	return _get_sfx_resource_duration(sound)

func _is_same_sfx_gas_emission(a: Resource, b: Resource) -> bool:
	return _is_same_sfx_resource(a, b)

func _initialize_gas_effects() -> void :
	_gas_effect_initial_rects.clear()
	_gas_effect_tweens.clear()
	_gas_effect_bag.clear()
	_gas_effect_last = null

	for child in gas_effects.get_children():
		if child is TextureRect:
			var effect: = child as TextureRect
			_gas_effect_initial_rects[effect] = {
				"position": effect.position, 
				"size": effect.size, 
			}
			effect.visible = false
			effect.modulate.a = 0.0

func _play_gas_effect() -> void :
	var effect: = _pop_next_gas_effect()
	if effect == null:
		return

	var initial_rect: Dictionary = _gas_effect_initial_rects.get(effect, {})
	if initial_rect.is_empty():
		return

	if _gas_effect_tweens.has(effect):
		var existing_tweens: Array = _gas_effect_tweens[effect]
		for existing_tween in existing_tweens:
			if existing_tween is Tween:
				existing_tween.kill()

	var start_position: Vector2 = _get_gas_effect_start_position()
	var target_rect: Dictionary = _get_effect_layout_rect(gas_effects, initial_rect)
	var target_position: Vector2 = target_rect["position"]
	var target_size: Vector2 = target_rect["size"]
	var fade_in_duration: = clampf(gas_effect_fade_in_duration, 0.0, gas_effect_duration)
	var fade_out_duration: = clampf(gas_effect_fade_out_duration, 0.0, gas_effect_duration)
	var fade_total_duration: = fade_in_duration + fade_out_duration
	if fade_total_duration > gas_effect_duration and fade_total_duration > 0.0:
		var fade_scale: = gas_effect_duration / fade_total_duration
		fade_in_duration *= fade_scale
		fade_out_duration *= fade_scale
	var fade_hold_duration: = maxf(gas_effect_duration - fade_in_duration - fade_out_duration, 0.0)

	effect.visible = true
	effect.position = start_position
	effect.size = Vector2.ZERO
	effect.modulate.a = 0.0

	var motion_tween: = create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(effect, "position", target_position, gas_effect_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(effect, "size", target_size, gas_effect_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var fade_tween: = create_tween()
	fade_tween.tween_property(effect, "modulate:a", 1.0, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.tween_interval(fade_hold_duration)
	fade_tween.tween_property(effect, "modulate:a", 0.0, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_tween.tween_callback(_finish_gas_effect.bind(effect))

	_gas_effect_tweens[effect] = [motion_tween, fade_tween]

func _finish_gas_effect(effect: TextureRect) -> void :
	if not _gas_effect_initial_rects.has(effect):
		return

	var initial_rect: Dictionary = _gas_effect_initial_rects[effect]
	var target_rect: Dictionary = _get_effect_layout_rect(gas_effects, initial_rect)
	effect.position = target_rect["position"]
	effect.size = target_rect["size"]
	effect.modulate.a = 0.0
	effect.visible = false
	_gas_effect_tweens.erase(effect)

func _get_gas_effect_start_position() -> Vector2:
	var origin_position: Vector2 = gas_effects.get_global_transform().affine_inverse() * gas_emit_origin.global_position
	if _is_layout_flipped:
		origin_position.x = gas_effects.size.x - origin_position.x

	return origin_position

func _pop_next_gas_effect() -> TextureRect:
	if _gas_effect_bag.is_empty():
		_refill_gas_effect_bag()

	if _gas_effect_bag.is_empty():
		return null

	_move_available_gas_effect_to_front()
	_gas_effect_last = _gas_effect_bag[0]
	return _gas_effect_bag.pop_front()

func _refill_gas_effect_bag() -> void :
	_gas_effect_bag.clear()

	for effect in _gas_effect_initial_rects.keys():
		if effect is TextureRect:
			_gas_effect_bag.append(effect as TextureRect)

	_gas_effect_bag.shuffle()
	_move_available_gas_effect_to_front()

func _move_available_gas_effect_to_front() -> void :
	if _gas_effect_bag.size() <= 1:
		return

	for index in range(_gas_effect_bag.size()):
		var effect: = _gas_effect_bag[index]
		if effect != _gas_effect_last and not effect.visible:
			_swap_gas_effect_bag_item_to_front(index)
			return

	if _gas_effect_last != null and _gas_effect_bag[0] == _gas_effect_last:
		for index in range(1, _gas_effect_bag.size()):
			if _gas_effect_bag[index] != _gas_effect_last:
				_swap_gas_effect_bag_item_to_front(index)
				return

func _swap_gas_effect_bag_item_to_front(index: int) -> void :
	var replacement: = _gas_effect_bag[index]
	_gas_effect_bag[index] = _gas_effect_bag[0]
	_gas_effect_bag[0] = replacement

func _initialize_breathe_effects() -> void :
	_breathe_effect_list.clear()
	_breathe_effect_initial_rects.clear()
	_breathe_effect_current = null

	for child in breathe_effects.get_children():
		if child is TextureRect:
			var effect: = child as TextureRect
			_breathe_effect_initial_rects[effect] = {
				"position": effect.position, 
				"size": effect.size, 
			}
			effect.visible = false
			effect.modulate.a = 0.0
			_breathe_effect_list.append(effect)

func _start_breathe_effect_loop() -> void :
	if _breathe_effect_list.is_empty():
		return

	var effect: = _get_random_breathe_effect()
	if effect == null:
		return

	_breathe_effect_current = effect
	effect.visible = true
	effect.modulate.a = 0.0

	_breathe_effect_tween = create_tween()
	_breathe_effect_tween.tween_property(effect, "modulate:a", 1.0, BREATHE_EFFECT_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_effect_tween.tween_callback(_crossfade_breathe_effect)

func _crossfade_breathe_effect() -> void :
	var previous: = _breathe_effect_current
	var next: = _get_random_breathe_effect(previous)
	if next == null:
		return

	_breathe_effect_current = next
	next.visible = true
	next.modulate.a = 0.0

	_breathe_effect_tween = create_tween()
	_breathe_effect_tween.set_parallel(true)
	if previous != null:
		_breathe_effect_tween.tween_property(previous, "modulate:a", 0.0, BREATHE_EFFECT_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_effect_tween.tween_property(next, "modulate:a", 1.0, BREATHE_EFFECT_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_effect_tween.chain().tween_callback(_finish_breathe_effect_crossfade.bind(previous))

func _finish_breathe_effect_crossfade(previous: TextureRect) -> void :
	if previous != null and previous != _breathe_effect_current:
		previous.visible = false
		previous.modulate.a = 0.0

	_crossfade_breathe_effect()

func _get_random_breathe_effect(excluded_effect: TextureRect = null) -> TextureRect:
	if _breathe_effect_list.is_empty():
		return null

	if _breathe_effect_list.size() == 1:
		return _breathe_effect_list[0]

	var candidates: Array[TextureRect] = []
	for effect in _breathe_effect_list:
		if effect != excluded_effect:
			candidates.append(effect)

	return candidates[randi_range(0, candidates.size() - 1)]

func _is_valid_sfx_resource(sound: Resource) -> bool:
	if sound is SoundData:
		var data: = sound as SoundData
		return data.stream != null

	return sound is AudioStream

func _get_sfx_resource_duration(sound: Resource) -> float:
	var stream: = _get_sfx_resource_stream(sound)
	if stream == null:
		return 0.0

	return stream.get_length()

func _is_same_sfx_resource(a: Resource, b: Resource) -> bool:
	if a == b:
		return true

	var stream_a: = _get_sfx_resource_stream(a)
	var stream_b: = _get_sfx_resource_stream(b)
	if stream_a == null or stream_b == null:
		return false

	if stream_a == stream_b:
		return true

	return not stream_a.resource_path.is_empty() and stream_a.resource_path == stream_b.resource_path

func _get_sfx_resource_stream(sound: Resource) -> AudioStream:
	if sound is SoundData:
		var data: = sound as SoundData
		return data.stream
	elif sound is AudioStream:
		return sound as AudioStream

	return null

func _is_mobile_platform() -> bool:
	var os_name: String = OS.get_name()
	return os_name == "Android" or os_name == "iOS"
