extends Control

const DEBUG_PANEL_SCENE: String = "res://scenes/DebugPanel.tscn"
const DEBUG_TRANSITION_TYPE: int = 1
const DEBUG_TRANSITION_DURATION: float = 0.5
const SECRET_SEQUENCE: Array[int] = [1, 1, 2, 2, 1, 2, 1, 2, 1, 1]

@onready var button1: TextureButton = $Button1
@onready var button2: TextureButton = $Button2

var _secret_progress: Array[int] = []
var _is_transition_started: bool = false

func _ready() -> void :
	if not button1.pressed.is_connected(_on_button1_pressed):
		button1.pressed.connect(_on_button1_pressed)
	if not button2.pressed.is_connected(_on_button2_pressed):
		button2.pressed.connect(_on_button2_pressed)

func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and not visible:
		_reset_secret_progress()

func _on_button1_pressed() -> void :
	_advance_secret_sequence(1)

func _on_button2_pressed() -> void :
	_advance_secret_sequence(2)

func _advance_secret_sequence(value: int) -> void :
	if _is_transition_started:
		return

	_secret_progress.append(value)
	if _secret_progress.size() > SECRET_SEQUENCE.size():
		_secret_progress.pop_front()

	while not _secret_progress.is_empty() and not _is_secret_progress_prefix():
		_secret_progress.pop_front()

	if _secret_progress == SECRET_SEQUENCE:
		_transition_to_debug_panel()

func _reset_secret_progress() -> void :
	_secret_progress.clear()

func _is_secret_progress_prefix() -> bool:
	if _secret_progress.size() > SECRET_SEQUENCE.size():
		return false

	for index in range(_secret_progress.size()):
		if _secret_progress[index] != SECRET_SEQUENCE[index]:
			return false

	return true

func _transition_to_debug_panel() -> void :
	_is_transition_started = true
	GlobalVar.last_transition_type = DEBUG_TRANSITION_TYPE
	GlobalVar.last_transition_duration = DEBUG_TRANSITION_DURATION

	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(DEBUG_PANEL_SCENE, DEBUG_TRANSITION_TYPE, DEBUG_TRANSITION_DURATION)
	else:
		get_tree().change_scene_to_file(DEBUG_PANEL_SCENE)
