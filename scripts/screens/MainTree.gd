extends Control

@export_group("BGM Settings")
@export var bgm: Resource

const ORIGINAL_DIRECTION_LOCALES: = ["ja"]

const SKY_SCROLL_SPEED: = 12.0
const SKY_LOOP_WIDTH: = 540.0
const LANGUAGE_CYCLE_ORDER: Array[String] = ["ja", "en", "zh", "ko"]
const LANGUAGE_BUTTON_IDLE_ALPHA: = 0.4
const LANGUAGE_BUTTON_HOVER_ALPHA: = 1.0
const LANGUAGE_BUTTON_ALPHA_TWEEN_DURATION: = 0.15
const LOCALIZED_LABEL_KEYS: = {
	"ButtonContainer/Start/Label": "MM_START", 
	"ButtonContainer/Replay/Label": "MM_REPLAY", 
	"ButtonContainer/Bonus/Label": "MM_BONUS", 
	"ButtonContainer/Settings/Label": "MM_SETTING", 
	"ButtonContainer/Credits/Label": "MM_CREDITS", 
	"ButtonContainer/Quit/Label": "MM_QUIT", 
	"ReplayPanel/Back/Label": "BT_BACK", 
	"OptionPanel/Back/Label": "BT_BACK", 
	"CreditPanel/Back/Label": "BT_BACK", 
	"BonusPanel/Back/Label": "BT_BACK", 
}

@onready var background_sky: TextureRect = $Background / Sky
@onready var background_car: TextureRect = $Background / Car
@onready var background_dirt: TextureRect = $Background / Dirt

@onready var title_trial: TextureRect = $Title / TrialVer

@onready var title: CanvasItem = $Title
@onready var button_container: VBoxContainer = $ButtonContainer
@onready var bonus_button: CanvasItem = $ButtonContainer / Bonus
@onready var replay_panel: Control = $ReplayPanel
@onready var option_panel: Control = $OptionPanel
@onready var credit_panel: Control = $CreditPanel
@onready var play_panel: Control = $PlayPanel
@onready var bonus_panel: Control = $BonusPanel
@onready var language_cycle: TextureButton = $Language

var _background_sky_neutral_x: = 0.0
var _background_sky_loop_start_x: = 0.0
var _background_sky_loop_end_x: = 0.0
var _background_sky_direction: = -1.0
var _background_flip_state: = -1
var _language_button_tween: Tween

func _ready() -> void :
	if OS.get_name() == "iOS":
		var quit_button: CanvasItem = button_container.get_node_or_null("Quit")
		if quit_button:
			quit_button.hide()
	_background_sky_neutral_x = background_sky.position.x
	_setup_language_cycle_button()
	_play_bgm()
	_apply_locale_direction()
	_update_localized_labels()
	_update_bonus_button_visibility()
	_update_background_dirt_visibility()
	title_trial.visible = GlobalVar.is_trial_version
	var should_open_replay_panel: bool = GlobalVar.open_replay_panel_on_main
	GlobalVar.open_replay_panel_on_main = false
	title.visible = not should_open_replay_panel
	button_container.visible = not should_open_replay_panel
	language_cycle.visible = not should_open_replay_panel
	replay_panel.visible = should_open_replay_panel
	option_panel.visible = false
	credit_panel.visible = false
	play_panel.visible = false
	bonus_panel.visible = false

func _play_bgm() -> void :
	if bgm == null:
		return

	AudioManager.play_any_bgm(bgm)

func _setup_language_cycle_button() -> void :
	_set_language_button_alpha(LANGUAGE_BUTTON_IDLE_ALPHA)
	if not language_cycle.mouse_entered.is_connected(_on_language_cycle_mouse_entered):
		language_cycle.mouse_entered.connect(_on_language_cycle_mouse_entered)
	if not language_cycle.mouse_exited.is_connected(_on_language_cycle_mouse_exited):
		language_cycle.mouse_exited.connect(_on_language_cycle_mouse_exited)
	if not language_cycle.pressed.is_connected(_on_language_cycle_pressed):
		language_cycle.pressed.connect(_on_language_cycle_pressed)

func _on_language_cycle_mouse_entered() -> void :
	_animate_language_button_alpha(LANGUAGE_BUTTON_HOVER_ALPHA)

func _on_language_cycle_mouse_exited() -> void :
	_animate_language_button_alpha(LANGUAGE_BUTTON_IDLE_ALPHA)

func _on_language_cycle_pressed() -> void :
	var current_locale: = TranslationServer.get_locale().get_slice("_", 0)
	var current_index: = LANGUAGE_CYCLE_ORDER.find(current_locale)
	var next_index: = 0 if current_index == -1 else (current_index + 1) % LANGUAGE_CYCLE_ORDER.size()
	var next_locale: String = LANGUAGE_CYCLE_ORDER[next_index]
	SaveManager.update_setting("locale", next_locale)

func _animate_language_button_alpha(target_alpha: float) -> void :
	if _language_button_tween:
		_language_button_tween.kill()
	_language_button_tween = create_tween()
	_language_button_tween.tween_property(language_cycle, "modulate:a", target_alpha, LANGUAGE_BUTTON_ALPHA_TWEEN_DURATION)

func _set_language_button_alpha(alpha: float) -> void :
	var color: = language_cycle.modulate
	color.a = alpha
	language_cycle.modulate = color

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_locale_direction()
		_update_localized_labels()

func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		_close_open_panel()

func _process(delta: float) -> void :
	background_sky.position.x += SKY_SCROLL_SPEED * _background_sky_direction * delta

	if _background_sky_direction < 0.0 and background_sky.position.x <= _background_sky_loop_end_x:
		background_sky.position.x = _background_sky_loop_start_x
	elif _background_sky_direction > 0.0 and background_sky.position.x >= _background_sky_loop_end_x:
		background_sky.position.x = _background_sky_loop_start_x

func _apply_locale_direction() -> void :
	var language: = TranslationServer.get_locale().get_slice("_", 0)
	var is_flipped: = language not in ORIGINAL_DIRECTION_LOCALES
	var next_flip_state: = 1 if is_flipped else 0
	if next_flip_state == _background_flip_state:
		return
	_background_flip_state = next_flip_state

	background_car.flip_h = is_flipped
	background_dirt.flip_h = is_flipped

	if is_flipped:
		_background_sky_direction = 1.0
		_background_sky_loop_start_x = _background_sky_neutral_x - SKY_LOOP_WIDTH
		_background_sky_loop_end_x = _background_sky_neutral_x
	else:
		_background_sky_direction = -1.0
		_background_sky_loop_start_x = _background_sky_neutral_x
		_background_sky_loop_end_x = _background_sky_neutral_x - SKY_LOOP_WIDTH

	background_sky.position.x = _background_sky_loop_start_x

func _update_localized_labels() -> void :
	for label_path in LOCALIZED_LABEL_KEYS.keys():
		var label: = get_node_or_null(label_path) as Label
		if label:
			label.text = tr(LOCALIZED_LABEL_KEYS[label_path])

func _close_open_panel() -> void :
	if replay_panel.visible:
		replay_panel.visible = false
		button_container.visible = true
		title.visible = true
		language_cycle.visible = true
		get_viewport().set_input_as_handled()
		return

	if option_panel.visible:
		option_panel.visible = false
		button_container.visible = true
		title.visible = true
		language_cycle.visible = true
		get_viewport().set_input_as_handled()
		return

	if credit_panel.visible:
		credit_panel.visible = false
		button_container.visible = true
		title.visible = true
		language_cycle.visible = true
		get_viewport().set_input_as_handled()
		return

	if play_panel.visible:
		play_panel.visible = false
		button_container.visible = true
		title.visible = true
		language_cycle.visible = true
		get_viewport().set_input_as_handled()
		return

	if bonus_panel.visible:
		bonus_panel.visible = false
		button_container.visible = true
		title.visible = true
		language_cycle.visible = true
		get_viewport().set_input_as_handled()
		return

func _update_bonus_button_visibility() -> void :
	bonus_button.visible = _are_all_endings_unlocked()

func _update_background_dirt_visibility() -> void :
	background_dirt.modulate.a = 1.0 if SaveManager.is_ending_unlocked(8) else 0.0

func _are_all_endings_unlocked() -> bool:
	for ending_index in range(1, SaveManager.ENDING_COUNT + 1):
		if not SaveManager.is_ending_unlocked(ending_index):
			return false
	return true
