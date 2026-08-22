extends TextureButton
class_name CustomButton


enum ButtonAction{
	NONE, 
	QUIT, 
	TOGGLE_NODES, 
	CHANGE_SCENE
}

@export_group("Action Settings")
@export var action_type: ButtonAction = ButtonAction.NONE
@export var nodes_to_show: Array[CanvasItem] = []
@export var nodes_to_hide: Array[CanvasItem] = []

@export_group("Sound Settings")
@export var press_sound: Resource
@export var hover_sound: Resource

@export_group("Scene Transition Settings")
@export_file("*.tscn") var target_scene_path: String = ""
@export_enum("FADE", "WIPE_L_R", "WIPE_R_L", "WIPE_T_B", "WIPE_B_T", "IRIS_CENTER") var transition_type: int = SceneTransition.TransitionType.FADE
@export var transition_duration: float = 0.5
@export var cutscene_id_to_play: String = ""
@export_file("*.tscn") var scene_path_after_cutscene: String = ""

var _is_quit_started: = false

func _ready() -> void :
	pressed.connect(_on_custom_pressed)
	mouse_entered.connect(_on_custom_mouse_entered)

func _on_custom_pressed() -> void :
	if _is_quit_started:
		return

	if press_sound:
		AudioManager.play_any_sfx(press_sound)

	match action_type:
		ButtonAction.QUIT:
			_is_quit_started = true
			disabled = true
			await _handle_quit()
		ButtonAction.TOGGLE_NODES:
			_handle_node_visibility()
		ButtonAction.CHANGE_SCENE:
			_handle_scene_change()

func _on_custom_mouse_entered() -> void :
	if hover_sound:
		AudioManager.play_any_sfx(hover_sound)

func _handle_quit() -> void :
	if has_node("/root/SceneTransition") and SceneTransition.has_method("close_to_black"):
		await SceneTransition.close_to_black(transition_type, transition_duration)
	get_tree().quit()

func _handle_node_visibility() -> void :
	for node in nodes_to_show:
		if node: node.show()
	for node in nodes_to_hide:
		if node: node.hide()

func _handle_scene_change() -> void :
	if target_scene_path == "":
		return

	disabled = true
	GlobalVar.last_transition_type = transition_type
	GlobalVar.last_transition_duration = transition_duration

	if cutscene_id_to_play != "":
		GlobalVar.play_cutscene_id = cutscene_id_to_play
		GlobalVar.auto_transition_after_cutscene = scene_path_after_cutscene

	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(target_scene_path, transition_type, transition_duration)
	else:
		get_tree().change_scene_to_file(target_scene_path)
