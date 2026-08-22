extends CanvasLayer

const WIPE_H_RES: String = "res://data/images/vfx/linear_wipe_h.png"
const WIPE_V_RES: String = "res://data/images/vfx/linear_wipe_v.png"
const IRIS_CENTER_WIPE_RES: String = "res://data/images/vfx/iris_wipe_center.png"
const IRIS_END_WIPE_RES_FORMAT: String = "res://data/images/vfx/iris_wipe_end%d.png"
const IRIS_END_HFLIP_WIPE_RES_FORMAT: String = "res://data/images/vfx/iris_wipe_end%d_hflip.png"
const HFLIP_IRIS_ENDINGS: Array[int] = [6]
const HFLIP_IRIS_LOCALES: Array[String] = ["ko", "en", "zh"]

const WAIT_TIME_AFTER_DARKNESS = 0.2
const SHADER_SMOOTH_MARGIN = 0.1
const CUTSCENE_PLAYER_SCENE: = "res://scenes/CutscenePlayer.tscn"
const MAIN_TREE_SCENE: = "res://scenes/MainTree.tscn"

enum TransitionType{FADE, WIPE_L_R, WIPE_R_L, WIPE_T_B, WIPE_B_T, IRIS_CENTER}

@onready var color_rect: ColorRect = $ColorRect
@onready var material: ShaderMaterial = color_rect.material

var _is_transitioning: = false
var _next_iris_wipe_path: String = ""
var _active_iris_wipe_path: String = IRIS_CENTER_WIPE_RES

func _ready() -> void :
	_set_progress(0.0)
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_next_iris_wipe_mask_from_cutscene_id(cutscene_id: String) -> void :
	var ending_index: int = _get_ending_index_from_cutscene_id(cutscene_id)
	if ending_index == 0:
		_next_iris_wipe_path = ""
		return
	set_next_iris_wipe_mask_for_ending(ending_index)

func set_next_iris_wipe_mask_for_ending(ending_index: int) -> void :
	var clamped_ending_index: int = clampi(ending_index, 1, 8)
	var path: String = _get_ending_iris_wipe_path(clamped_ending_index)
	if _resource_exists(path):
		_next_iris_wipe_path = path
	else:
		_next_iris_wipe_path = ""
		push_warning("SceneTransition: Ending iris wipe image not found: %s" % path)

func _get_ending_iris_wipe_path(ending_index: int) -> String:
	if _should_use_hflip_iris_wipe(ending_index):
		var hflip_path: String = IRIS_END_HFLIP_WIPE_RES_FORMAT % ending_index
		if _resource_exists(hflip_path):
			return hflip_path

	return IRIS_END_WIPE_RES_FORMAT % ending_index

func _should_use_hflip_iris_wipe(ending_index: int) -> bool:
	return ending_index in HFLIP_IRIS_ENDINGS and _get_current_language() in HFLIP_IRIS_LOCALES

func _get_current_language() -> String:
	return TranslationServer.get_locale().get_slice("_", 0)

func change_scene(target_path: String, type: int = TransitionType.FADE, duration: float = 0.5) -> void :
	await change_scene_split(target_path, type, type, duration)

func change_scene_split(target_path: String, close_type: int, open_type: int, duration: float = 0.5) -> void :
	if _is_transitioning or target_path == "":
		return

	_is_transitioning = true
	_active_iris_wipe_path = _resolve_iris_wipe_path(target_path)
	_next_iris_wipe_path = ""
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _play_close_transition(close_type, duration, target_path)

	if WAIT_TIME_AFTER_DARKNESS > 0.0:
		await get_tree().create_timer(WAIT_TIME_AFTER_DARKNESS).timeout

	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame
	await get_tree().process_frame

	await _play_open_transition(open_type, duration)

	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	_active_iris_wipe_path = IRIS_CENTER_WIPE_RES

func close_to_black(type: int = TransitionType.FADE, duration: float = 0.5) -> void :
	if _is_transitioning:
		return

	_is_transitioning = true
	_active_iris_wipe_path = IRIS_CENTER_WIPE_RES
	_next_iris_wipe_path = ""
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _play_close_transition(type, duration, "")

func fade_from_black(duration: float = 0.4) -> void :
	color_rect.material = null
	color_rect.modulate.a = 1.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_to_black(duration: float = 0.4) -> void :
	color_rect.material = null
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished

func set_transparent() -> void :
	color_rect.material = null
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _play_close_transition(type: int, duration: float, target_path: String) -> void :
	if AudioManager.has_method("stop_bgm"):
		AudioManager.stop_bgm(duration)
	if AudioManager.has_method("stop_all_sfx") and _should_stop_sfx_for_transition(target_path):
		AudioManager.stop_all_sfx(duration)

	if type == TransitionType.FADE:
		color_rect.material = null
		color_rect.modulate.a = 0.0
		var _tween: = create_tween()
		_tween.tween_property(color_rect, "modulate:a", 1.0, duration)
		await _tween.finished
		return

	color_rect.material = material
	color_rect.modulate.a = 1.0
	_prepare_shader(type, false)
	_set_progress(0.0)
	await get_tree().process_frame
	var tween: = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0 + SHADER_SMOOTH_MARGIN, duration)
	await tween.finished

func _should_stop_sfx_for_transition(target_path: String) -> bool:
	var current_scene: = get_tree().current_scene
	if current_scene == null:
		return false

	var current_path: = current_scene.scene_file_path
	return current_path == CUTSCENE_PLAYER_SCENE and target_path in [MAIN_TREE_SCENE, CUTSCENE_PLAYER_SCENE]

func _play_open_transition(type: int, duration: float) -> void :
	if type == TransitionType.FADE:
		color_rect.material = null
		color_rect.modulate.a = 1.0
		var _tween: = create_tween()
		_tween.tween_property(color_rect, "modulate:a", 0.0, duration)
		await _tween.finished
		return

	color_rect.material = material
	color_rect.modulate.a = 1.0
	_prepare_shader(type, true)
	_set_progress(1.0 + SHADER_SMOOTH_MARGIN)
	await get_tree().process_frame
	var tween: = create_tween()
	tween.tween_method(_set_progress, 1.0 + SHADER_SMOOTH_MARGIN, 0.0, duration)
	await tween.finished

func _set_progress(value: float) -> void :
	if material:
		material.set_shader_parameter("progress", value)

func _prepare_shader(type: int, is_opening: bool) -> void :
	if not material:
		return

	material.set_shader_parameter("is_mask", type == TransitionType.IRIS_CENTER)

	match type:
		TransitionType.WIPE_R_L:
			_setup_wipe(WIPE_V_RES, is_opening, false)
		TransitionType.WIPE_L_R:
			_setup_wipe(WIPE_V_RES, not is_opening, false)
		TransitionType.WIPE_B_T:
			_setup_wipe(WIPE_H_RES, false, is_opening)
		TransitionType.WIPE_T_B:
			_setup_wipe(WIPE_H_RES, false, not is_opening)
		TransitionType.IRIS_CENTER:
			_setup_wipe(_active_iris_wipe_path, false, false)
		_:
			pass

func _setup_wipe(path: String, flip_h: bool, flip_v: bool) -> void :
	material.set_shader_parameter("mask_texture", load(path))
	material.set_shader_parameter("flip_h", flip_h)
	material.set_shader_parameter("flip_v", flip_v)

func _resolve_iris_wipe_path(_target_path: String) -> String:
	if _next_iris_wipe_path != "" and _resource_exists(_next_iris_wipe_path):
		return _next_iris_wipe_path

	return IRIS_CENTER_WIPE_RES

func _get_ending_index_from_cutscene_id(cutscene_id: String) -> int:
	var file_stem: String = cutscene_id.strip_edges().get_file().get_basename().to_lower()
	if not file_stem.begins_with("ending"):
		return 0

	var ending_index_text: String = file_stem.substr("ending".length())
	if not ending_index_text.is_valid_int():
		return 0

	return clampi(int(ending_index_text), 1, 8)

func _resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)
