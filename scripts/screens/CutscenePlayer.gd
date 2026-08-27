extends CanvasLayer

@onready var cut_container: Control = $CutContainer
@onready var dialogue_manager: DialogueManager = $DialogueManager
@onready var skip_button: TextureButton = $SkipButton
@onready var cutscene_title: Label = $CutsceneTitle
@onready var replay_button: TextureButton = $ReplayButton

const SE_BASE_DIR: = "res://data/se/"
const BGM_DIR: = "res://data/bgm/"
const SE_SEARCH_DIRS: Array[String] = [
	"res://data/se/", 
	"res://data/se/bowel/", 
	"res://data/se/life/", 
	"res://data/se/system/", 
]
const CUTSCENE_CSV_PATH: = "res://data/cutscenes/%s.csv"
const CUTSCENE_PLAYER_SCENE: = "res://scenes/CutscenePlayer.tscn"
const CUTSCENE_IMG_DIR: = "res://data/images/cutscene/"
const CUTSCENE_CENSORED_IMG_DIR: = "res://data/images/cutscene_censored/"
const OFFSET_CSV_PATH: = "res://data/cutscenes/cutscene_image_position_offset.csv"
const GENERATED_CENSOR_OFFSET_CSV_PATH: = "res://data/cutscenes/cutscene_censor_overlay_offset.csv"
const MOSAIC_SHADER_PATH: = "res://shader/mosaic_censor.gdshader"

const DEFAULT_CUTSCENE_ID: = "ending1"
const HORIZONTAL_FLIP_CUTSCENE_IDS: Array[String] = ["ending6"]
const HORIZONTAL_FLIP_LOCALES: Array[String] = ["ko", "en", "zh"]
const START_WAIT_TIME: float = 1.5
const END_WAIT_TIME: float = 1.0
const MAX_LAYER_INDEX: int = 16

const SKIP_BUTTON_VISIBLE_POS: Vector2 = Vector2(10.0, 10.0)
const SKIP_BUTTON_SIZE: Vector2 = Vector2(130.0, 36.0)
const SKIP_BUTTON_TRIGGER_RANGE: float = 80.0
const MOBILE_SKIP_BUTTON_TOUCH_MARGIN: float = 20.0
const SKIP_BUTTON_MOVE_DURATION: float = 0.18
const SKIP_BUTTON_INITIAL_VISIBLE_TIME: float = 1.0
const SKIP_BUTTON_CANVAS_LAYER: int = 10
const SKIP_BUTTON_Z_INDEX: int = 4096
const REPLAY_TRANSITION_TYPE: int = 5

const FINAL_UI_MOVE_DURATION: float = 0.5
const CUTSCENE_TITLE_IDLE_HIDE_DELAY: float = 3.0
const FINAL_UI_VISIBLE_DISTANCE: float = 1.0
const UNKNOWN_CUTSCENE_TITLE: = "Unknown title"
const OFFSCREEN_MARGIN: float = 16.0

const REF_WIDTH: float = 540.0
const REF_HEIGHT: float = 960.0
const TEXTURE_PRELOAD_POST_TRANSITION_MARGIN: float = 0.1
const TEXTURE_PRELOAD_LOOKAHEAD_COUNT: int = 2

var is_skipped: = false
var _events: Array[Dictionary] = []
var _current_event_index: = 0
var _current_tween: Tween
var _current_tex_rect: TextureRect
var _current_target_pos: = Vector2.ZERO
var _is_event_skippable: = false
var _skip_armed_frame: = -1
var _can_skip_cutscene: = false
var _is_in_final_wait: = false

var _cutscene_id: = ""
var _crop_metadata: Dictionary = {}
var _se_path_cache: Dictionary = {}
var _bgm_path_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _texture_load_requests: Dictionary = {}
var _texture_keep_paths: Dictionary = {}
var _texture_streaming_enabled: = false
var _mosaic_shader: Shader

var _skip_button_tween: Tween
var _skip_button_layer: CanvasLayer
var _skip_button_visible: = false
var _skip_button_auto_hide_serial: int = 0
var _skip_button_visible_pos: = Vector2.ZERO
var _skip_button_hidden_pos: = Vector2.ZERO
var _skip_button_activation_rect: Rect2
var _cutscene_title_tween: Tween
var _cutscene_title_visible_pos: = Vector2.ZERO
var _cutscene_title_hidden_pos: = Vector2.ZERO
var _replay_button_visible_pos: = Vector2.ZERO
var _replay_button_hidden_pos: = Vector2.ZERO
var _cutscene_title_idle_timer: = Timer.new()
var _is_replay_transition_started: = false

var _played_bgm_indices: Dictionary = {}
var _button_handled_frame: = -1
var _active_sfx_players: Array[AudioStreamPlayer] = []

signal event_skipped
signal cutscene_finished

func _ready() -> void :
	_load_crop_metadata()
	_setup_skip_button()
	_setup_cutscene_title()

	_cutscene_id = _get_cutscene_id()
	dialogue_manager.set_dialogue_box_flip_h(_should_flip_cutscene_h())
	_apply_cutscene_iris_wipe_mask(_cutscene_id)
	_events = _load_cutscene_from_csv(_cutscene_id)

	if _events.is_empty():
		push_error("CutscenePlayer: No events found for cutscene '%s'." % _cutscene_id)
		_events = [{"type": "wait", "time": 3.0}, {"type": "final_wait"}]

	_enable_texture_streaming_after_transition()

	_can_skip_cutscene = false
	get_tree().create_timer(maxf(GlobalVar.last_transition_duration, 0.0)).timeout.connect(_enable_cutscene_skip)
	_play_cutscene()

func _exit_tree() -> void :
	_texture_cache.clear()
	_texture_keep_paths.clear()
	_texture_load_requests.clear()

func _get_cutscene_id() -> String:
	var id: = GlobalVar.play_cutscene_id.strip_edges()
	return DEFAULT_CUTSCENE_ID if id == "" else id

func _should_flip_cutscene_h() -> bool:
	return _get_cutscene_file_stem(_cutscene_id) in HORIZONTAL_FLIP_CUTSCENE_IDS and _get_current_language() in HORIZONTAL_FLIP_LOCALES

func _get_cutscene_file_stem(cutscene_id: String) -> String:
	return cutscene_id.get_file().get_basename().to_lower()

func _get_current_language() -> String:
	return TranslationServer.get_locale().get_slice("_", 0)

func _apply_cutscene_iris_wipe_mask(cutscene_id: String) -> void :
	if has_node("/root/SceneTransition") and SceneTransition.has_method("set_next_iris_wipe_mask_from_cutscene_id"):
		SceneTransition.set_next_iris_wipe_mask_from_cutscene_id(cutscene_id)

func _get_cutscene_title_text() -> String:
	var file_stem: = _get_cutscene_file_stem(_cutscene_id)
	if not file_stem.begins_with("ending"):
		return UNKNOWN_CUTSCENE_TITLE

	var ending_index_text: = file_stem.substr("ending".length())
	if not ending_index_text.is_valid_int():
		return UNKNOWN_CUTSCENE_TITLE

	return tr("ENDING_DESC_%d" % int(ending_index_text))

func _input(event: InputEvent) -> void :
	_handle_skip_button_activation(event)
	_handle_cutscene_title_interaction(event)

	if event.is_action_pressed("ui_accept") and _can_skip_current_event():
		_skip_current_event()
		get_viewport().set_input_as_handled()
		return

	var click_position: = Vector2.ZERO
	var has_click: = false
	var is_mobile_touch: = false
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
		click_position = mouse_event.position
		has_click = true
		is_mobile_touch = _is_mobile_platform()

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null and touch_event.pressed:
		click_position = touch_event.position
		has_click = true
		is_mobile_touch = true

	if not has_click:
		return

	if _handle_replay_button_click(click_position):
		get_viewport().set_input_as_handled()
		_button_handled_frame = Engine.get_process_frames()
		return

	if _handle_skip_button_click(click_position, is_mobile_touch):
		get_viewport().set_input_as_handled()
		return

	if _handle_final_wait_click(click_position, is_mobile_touch):
		get_viewport().set_input_as_handled()
		return

	if _is_event_skippable and Engine.get_process_frames() > _skip_armed_frame:
		_skip_current_event()

func _can_skip_current_event() -> bool:
	return _is_event_skippable and Engine.get_process_frames() > _skip_armed_frame

func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel") and _can_skip_cutscene and not is_skipped:
		_skip_cutscene()

func _setup_skip_button() -> void :
	_move_skip_button_to_top_layer()
	skip_button.size = SKIP_BUTTON_SIZE
	skip_button.z_as_relative = false
	skip_button.z_index = SKIP_BUTTON_Z_INDEX
	skip_button.modulate.a = 1.0
	_skip_button_visible_pos = SKIP_BUTTON_VISIBLE_POS
	_skip_button_hidden_pos = _get_top_hidden_position(skip_button, _skip_button_visible_pos)
	skip_button.position = _skip_button_hidden_pos
	skip_button.disabled = true
	_skip_button_visible = false
	_skip_button_activation_rect = Rect2(SKIP_BUTTON_VISIBLE_POS, SKIP_BUTTON_SIZE).grow(SKIP_BUTTON_TRIGGER_RANGE)
	if not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)

func _move_skip_button_to_top_layer() -> void :
	if _skip_button_layer == null:
		_skip_button_layer = CanvasLayer.new()
		_skip_button_layer.name = "SkipButtonLayer"
		_skip_button_layer.layer = SKIP_BUTTON_CANVAS_LAYER
		add_child(_skip_button_layer)

	if skip_button.get_parent() == _skip_button_layer:
		return

	var parent: = skip_button.get_parent()
	if parent:
		parent.remove_child(skip_button)
	_skip_button_layer.add_child(skip_button)

func _setup_cutscene_title() -> void :
	_cutscene_title_visible_pos = cutscene_title.position
	_cutscene_title_hidden_pos = _get_bottom_hidden_position(cutscene_title, _cutscene_title_visible_pos)
	cutscene_title.visible = false
	cutscene_title.position = _cutscene_title_hidden_pos
	cutscene_title.modulate.a = 1.0
	cutscene_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	replay_button.z_as_relative = false
	replay_button.z_index = SKIP_BUTTON_Z_INDEX
	_replay_button_visible_pos = replay_button.position
	_replay_button_hidden_pos = _get_top_hidden_position(replay_button, _replay_button_visible_pos)
	replay_button.visible = false
	replay_button.position = _replay_button_hidden_pos
	replay_button.modulate.a = 1.0
	replay_button.disabled = true
	_cutscene_title_idle_timer.one_shot = true
	add_child(_cutscene_title_idle_timer)
	if not _cutscene_title_idle_timer.timeout.is_connected(_hide_cutscene_title):
		_cutscene_title_idle_timer.timeout.connect(_hide_cutscene_title)
	if not replay_button.pressed.is_connected(_on_replay_button_pressed):
		replay_button.pressed.connect(_on_replay_button_pressed)

func _enable_cutscene_skip() -> void :
	_can_skip_cutscene = true
	_show_skip_button(true)

func _handle_skip_button_activation(event: InputEvent) -> void :
	if not _can_skip_cutscene or is_skipped or _is_in_final_wait:
		_hide_skip_button(true)
		return

	var motion_event: = event as InputEventMouseMotion
	if motion_event:
		if _skip_button_activation_rect.has_point(motion_event.position):
			_show_skip_button()
		elif _skip_button_visible and not skip_button.get_global_rect().has_point(motion_event.position):
			_hide_skip_button()

func _handle_cutscene_title_interaction(event: InputEvent) -> void :
	if not _is_in_final_wait:
		return
	if event is InputEventMouseMotion:
		_show_cutscene_title()

func _handle_replay_button_click(click_position: Vector2) -> bool:
	if not _is_in_final_wait or _is_replay_transition_started:
		return false
	if replay_button.disabled or not replay_button.visible:
		return false
	if not replay_button.get_global_rect().has_point(click_position):
		return false

	_handle_replay_button_pressed()
	return true

func _handle_skip_button_click(click_position: Vector2, is_mobile_touch: bool) -> bool:
	if not _can_skip_cutscene or is_skipped or _is_in_final_wait:
		return false

	if _skip_button_visible and skip_button.get_global_rect().has_point(click_position):
		_button_handled_frame = Engine.get_process_frames()
		_handle_skip_button_pressed()
		return true

	if not is_mobile_touch:
		return false

	var mobile_touch_rect: = Rect2(_skip_button_visible_pos, skip_button.size).grow(MOBILE_SKIP_BUTTON_TOUCH_MARGIN)
	if not mobile_touch_rect.has_point(click_position):
		return false

	if not _skip_button_visible:
		_show_skip_button(true)
	return true

func _handle_final_wait_click(_click_position: Vector2, is_mobile_touch: bool) -> bool:
	if not _is_in_final_wait:
		return false

	if is_mobile_touch and not _is_final_ui_fully_visible():
		_show_cutscene_title()
		return true

	if _is_event_skippable and Engine.get_process_frames() > _skip_armed_frame:
		_skip_current_event()
	return true

func _is_mobile_platform() -> bool:
	return OS.get_name() in ["Android", "iOS"]

func _show_skip_button(auto_hide: bool = false) -> void :
	if _skip_button_visible and not skip_button.disabled:
		if auto_hide:
			_schedule_skip_button_auto_hide()
		return
	_skip_button_visible = true
	skip_button.visible = true
	skip_button.disabled = false
	if _skip_button_tween:
		_skip_button_tween.kill()
	_skip_button_tween = create_tween()
	_skip_button_tween.tween_property(skip_button, "position", _skip_button_visible_pos, SKIP_BUTTON_MOVE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if auto_hide:
		_schedule_skip_button_auto_hide()

func _hide_skip_button(immediate: bool = false) -> void :
	if not immediate and not _skip_button_visible and skip_button.disabled:
		return
	_skip_button_visible = false
	skip_button.disabled = true
	if _skip_button_tween:
		_skip_button_tween.kill()
	if immediate:
		skip_button.position = _skip_button_hidden_pos
		skip_button.visible = false
		return
	_skip_button_tween = create_tween()
	_skip_button_tween.tween_property(skip_button, "position", _skip_button_hidden_pos, SKIP_BUTTON_MOVE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_skip_button_tween.tween_callback(
		func():
			skip_button.visible = false
	)

func _schedule_skip_button_auto_hide() -> void :
	_skip_button_auto_hide_serial += 1
	var serial: int = _skip_button_auto_hide_serial
	await get_tree().create_timer(SKIP_BUTTON_INITIAL_VISIBLE_TIME).timeout
	if serial != _skip_button_auto_hide_serial:
		return
	if not _can_skip_cutscene or is_skipped or _is_in_final_wait:
		return
	_hide_skip_button()

func _show_cutscene_title() -> void :
	if _cutscene_title_tween:
		_cutscene_title_tween.kill()
	cutscene_title.visible = true
	replay_button.visible = true
	replay_button.disabled = false
	_cutscene_title_tween = create_tween()
	_cutscene_title_tween.set_parallel(true)
	_cutscene_title_tween.tween_property(cutscene_title, "position", _cutscene_title_visible_pos, FINAL_UI_MOVE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cutscene_title_tween.tween_property(replay_button, "position", _replay_button_visible_pos, FINAL_UI_MOVE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cutscene_title_idle_timer.start(CUTSCENE_TITLE_IDLE_HIDE_DELAY)

func _hide_cutscene_title() -> void :
	if _cutscene_title_tween:
		_cutscene_title_tween.kill()
	_cutscene_title_tween = create_tween()
	_cutscene_title_tween.set_parallel(true)
	_cutscene_title_tween.tween_property(cutscene_title, "position", _cutscene_title_hidden_pos, FINAL_UI_MOVE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_cutscene_title_tween.tween_property(replay_button, "position", _replay_button_hidden_pos, FINAL_UI_MOVE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_cutscene_title_tween.chain().tween_callback(
		func():
			cutscene_title.visible = false
			replay_button.visible = false
			replay_button.disabled = true
	)

func _hide_cutscene_title_immediate() -> void :
	_cutscene_title_idle_timer.stop()
	if _cutscene_title_tween:
		_cutscene_title_tween.kill()
	cutscene_title.position = _cutscene_title_hidden_pos
	cutscene_title.visible = false
	replay_button.position = _replay_button_hidden_pos
	replay_button.visible = false
	replay_button.disabled = true

func _is_final_ui_fully_visible() -> bool:
	return (
		cutscene_title.visible
		and replay_button.visible
		and cutscene_title.position.distance_to(_cutscene_title_visible_pos) <= FINAL_UI_VISIBLE_DISTANCE
		and replay_button.position.distance_to(_replay_button_visible_pos) <= FINAL_UI_VISIBLE_DISTANCE
	)

func _get_top_hidden_position(control: Control, visible_pos: Vector2) -> Vector2:
	return Vector2(visible_pos.x, - maxf(control.size.y, 1.0) - OFFSCREEN_MARGIN)

func _get_bottom_hidden_position(control: Control, visible_pos: Vector2) -> Vector2:
	var viewport_height: float = get_viewport().get_visible_rect().size.y
	return Vector2(visible_pos.x, viewport_height + maxf(control.size.y, 1.0) + OFFSCREEN_MARGIN)

func _skip_cutscene() -> void :
	is_skipped = true
	_is_in_final_wait = false
	_hide_skip_button(true)
	_hide_cutscene_title_immediate()
	if bool(dialogue_manager.get("_is_line_pending")):
		dialogue_manager.dialogue_line_finished.emit("")
	dialogue_manager.force_reset()
	_skip_current_event()
	_on_cutscene_all_finished()

func _on_skip_button_pressed() -> void :
	if _button_handled_frame == Engine.get_process_frames():
		return
	_handle_skip_button_pressed()

func _handle_skip_button_pressed() -> void :
	if _can_skip_cutscene and not is_skipped:
		_skip_cutscene()

func _on_replay_button_pressed() -> void :
	if _button_handled_frame == Engine.get_process_frames():
		return
	_handle_replay_button_pressed()

func _handle_replay_button_pressed() -> void :
	if not _is_in_final_wait or _is_replay_transition_started:
		return

	_is_replay_transition_started = true
	_is_event_skippable = false
	_can_skip_cutscene = false
	_cutscene_title_idle_timer.stop()
	replay_button.disabled = true
	var replay_transition_duration: float = maxf(GlobalVar.last_transition_duration, 0.0)
	GlobalVar.play_cutscene_id = _cutscene_id
	GlobalVar.last_transition_type = REPLAY_TRANSITION_TYPE
	GlobalVar.last_transition_duration = replay_transition_duration
	set_process_input(false)
	set_process_unhandled_input(false)

	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(CUTSCENE_PLAYER_SCENE, REPLAY_TRANSITION_TYPE, replay_transition_duration)
	else:
		get_tree().change_scene_to_file(CUTSCENE_PLAYER_SCENE)

func _skip_current_event() -> void :
	if _current_tween:
		_current_tween.kill()
		_current_tween = null
	if _current_tex_rect:
		_current_tex_rect.modulate.a = 1.0
		_current_tex_rect.position = _current_target_pos
	_current_tex_rect = null
	_is_event_skippable = false
	event_skipped.emit()

func _play_cutscene() -> void :
	_current_event_index = 0
	while _current_event_index < _events.size():
		if is_skipped:
			return

		_update_texture_residency(_current_event_index)
		var event: = _events[_current_event_index]
		match String(event.get("type", "")):
			"checkpoint":
				pass
			"image":
				await _process_image_transition(event)
			"replace":
				await _process_replace_event(event)
			"remove":
				_process_remove_event(event)
			"clear":
				_clear_all_images()
			"wait":
				await _process_wait_event(float(event.get("time", 0.0)))
			"wait_click":
				await _process_wait_click_event(float(event.get("time", 0.0)))
			"sfx":
				await _process_sfx_event(event)
			"sfx_stop":
				AudioManager.stop_sfx(String(event.get("file", "")), float(event.get("fade", 0.3)))
			"bgm":
				if not _played_bgm_indices.has(_current_event_index):
					_played_bgm_indices[_current_event_index] = true
					_process_bgm_event(event)
			"dialogue_start":
				dialogue_manager.set_dialogue_box_placement(String(event.get("direction", "")))
				await dialogue_manager.start_dialogue(String(event.get("box_file", "")))
			"dialogue_change":
				dialogue_manager.change_dialogue_box(
					String(event.get("box_file", "")), 
					String(event.get("direction", ""))
				)
			"dialogue":
				await dialogue_manager.play_line(String(event.get("id", "")))
				await _wait_for_active_sfx_after_auto_dialogue()
			"dialogue_end":
				await dialogue_manager.end_dialogue()
			"final_wait":
				await _process_final_wait_event()

		_current_event_index += 1
		_update_texture_residency(_current_event_index)

	if not is_skipped:
		_on_cutscene_all_finished()

func _load_cutscene_from_csv(cutscene_id: String) -> Array[Dictionary]:
	var path: = _get_cutscene_csv_path(cutscene_id)
	var events: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_warning("CutscenePlayer: CSV not found: %s" % path)
		return events

	events.append({"type": "wait", "time": START_WAIT_TIME})

	var file: = FileAccess.open(path, FileAccess.READ)
	var header_row: = file.get_csv_line()
	var header: = _build_header_map(header_row)

	while not file.eof_reached():
		var row: = file.get_csv_line()
		if row.size() < header_row.size():
			continue

		var event: = _parse_cutscene_row(row, header)
		if event.is_empty():
			continue
		if _should_skip_for_censor_setting(event):
			continue
		events.append(event)

	events.append({"type": "wait", "time": END_WAIT_TIME})
	events.append({"type": "final_wait"})
	return events

func _get_cutscene_csv_path(cutscene_id: String) -> String:
	if cutscene_id.begins_with("res://"):
		return cutscene_id
	var file_name: = cutscene_id.to_lower()
	if file_name.get_extension() == "":
		return CUTSCENE_CSV_PATH % file_name
	return "res://data/cutscenes/%s" % file_name

func _build_header_map(header_row: PackedStringArray) -> Dictionary:
	var header: = {}
	for index in range(header_row.size()):
		header[header_row[index].strip_edges().to_lower()] = index
	return header

func _parse_cutscene_row(row: PackedStringArray, header: Dictionary) -> Dictionary:
	var raw_type: = _get_csv_cell(row, header, "type").to_lower()
	if raw_type == "":
		return {}

	var image_layer: = _parse_layered_event_type(raw_type, "image")
	var replace_layer: = _parse_layered_event_type(raw_type, "replace")
	var remove_layer: = _parse_layered_event_type(raw_type, "remove")
	var type: = raw_type
	if image_layer > 0:
		type = "image"
	elif replace_layer > 0:
		type = "replace"
	elif remove_layer > 0:
		type = "remove"

	var event: Dictionary = {"type": type}
	var path_or_id: = _get_csv_cell(row, header, "path_or_id")

	match type:
		"image":
			event["file"] = path_or_id
			event["trans"] = _get_csv_cell(row, header, "transition", "instant")
			event["dur"] = float(_get_csv_cell(row, header, "duration", "0.0"))
			event["dir"] = _get_csv_cell(row, header, "direction", "left")
			event["z"] = int(_get_csv_cell(row, header, "z_index", "0"))
			if image_layer > 0:
				event["layer"] = image_layer
		"replace":
			if replace_layer > 0:
				event["layer"] = replace_layer
				event["new_file"] = path_or_id
			else:
				var parts: = path_or_id.split(":")
				event["old_file"] = parts[0].strip_edges() if parts.size() > 0 else ""
				event["new_file"] = parts[1].strip_edges() if parts.size() > 1 else ""
		"remove":
			if remove_layer > 0:
				event["layer"] = remove_layer
			else:
				event["target_file"] = path_or_id
		"dialogue_start":
			event["box_file"] = path_or_id
			event["direction"] = _get_csv_cell(row, header, "direction")
		"dialogue_change":
			event["box_file"] = path_or_id
			event["direction"] = _get_csv_cell(row, header, "direction")
		"dialogue":
			event["id"] = path_or_id
		"dialogue_end", "clear", "checkpoint", "final_wait":
			pass
		"wait", "wait_click":
			event["time"] = float(_get_csv_cell(row, header, "duration", "0.0"))
		"sfx":
			event["file"] = path_or_id
			event["offset"] = float(_get_csv_cell(row, header, "duration", "0.0"))
			event["wait"] = _get_csv_cell(row, header, "wait_flag").to_lower() == "true"
		"sfx_stop":
			event["file"] = path_or_id
			event["fade"] = float(_get_csv_cell(row, header, "duration", "0.3"))
		"bgm":
			event["file"] = path_or_id
			event["fade"] = float(_get_csv_cell(row, header, "duration", "0.0"))
		_:
			push_warning("CutscenePlayer: Unknown event type '%s'." % raw_type)
			return {}

	return event

func _get_csv_cell(row: PackedStringArray, header: Dictionary, column_name: String, default_value: String = "") -> String:
	if not header.has(column_name):
		return default_value
	var index: = int(header[column_name])
	if index < 0 or index >= row.size():
		return default_value
	var value: = row[index].strip_edges()
	return default_value if value == "" else value

func _should_skip_for_censor_setting(event: Dictionary) -> bool:
	var type: = String(event.get("type", ""))
	var is_censor_event: = (
		(type == "image" and String(event.get("file", "")).contains("censor"))
		or (type == "replace" and String(event.get("new_file", "")).contains("censor"))
	)
	if not is_censor_event:
		return false
	if not GlobalVar.apply_censor:
		return true
	return GlobalVar.censor_line

func _parse_layered_event_type(raw_type: String, base_type: String) -> int:
	if not raw_type.begins_with(base_type):
		return 0

	var suffix: = raw_type.substr(base_type.length()).strip_edges()
	if suffix == "":
		return 0

	var layer_text: = suffix
	if suffix.begins_with("{") and suffix.ends_with("}"):
		layer_text = suffix.substr(1, suffix.length() - 2).strip_edges()

	if not layer_text.is_valid_int():
		return 0

	return clampi(int(layer_text), 1, MAX_LAYER_INDEX)

func _get_layer_slot_name(layer_index: int) -> String:
	return "image%d" % layer_index

func _enable_texture_streaming_after_transition() -> void :
	var delay: = maxf(GlobalVar.last_transition_duration, 0.0) + TEXTURE_PRELOAD_POST_TRANSITION_MARGIN
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	_texture_streaming_enabled = true
	_update_texture_residency(_current_event_index)

func _update_texture_residency(start_event_index: int) -> void :
	if not _texture_streaming_enabled:
		return

	var keep_paths: = _get_visible_texture_paths()
	var preload_paths: = _get_upcoming_texture_paths(start_event_index)
	for path in preload_paths:
		keep_paths[path] = true
	_texture_keep_paths = keep_paths

	for cached_path in _texture_cache.keys():
		if not _texture_keep_paths.has(cached_path):
			_texture_cache.erase(cached_path)

	for path in preload_paths:
		_request_texture_load(String(path))

func _get_visible_texture_paths() -> Dictionary:
	var paths: = {}
	for child in cut_container.get_children():
		if not child is TextureRect:
			continue
		var path: = String(child.get_meta("resolved_path", ""))
		if path != "":
			paths[path] = true
	return paths

func _get_upcoming_texture_paths(start_event_index: int) -> Array[String]:
	var paths: Array[String] = []
	var image_event_count: = 0
	for event_index in range(maxi(start_event_index, 0), _events.size()):
		var event: Dictionary = _events[event_index]
		var path: = _get_texture_path_for_event(event)
		if path == "":
			continue
		if not paths.has(path):
			paths.append(path)
		image_event_count += 1
		if image_event_count >= TEXTURE_PRELOAD_LOOKAHEAD_COUNT:
			break
	return paths

func _get_texture_path_for_event(event: Dictionary) -> String:
	var file_name: = ""
	match String(event.get("type", "")):
		"image":
			file_name = String(event.get("file", ""))
		"replace":
			file_name = String(event.get("new_file", ""))

	if file_name == "":
		return ""

	var layer_index: = int(event.get("layer", 0))
	var censor_base_file: = _find_base_file_for_censor_layer(layer_index) if _is_censor_file(file_name) else ""
	var path: = _get_cutscene_image_path(file_name, censor_base_file)
	return path if ResourceLoader.exists(path) else ""

func _request_texture_load(path: String) -> void :
	if path == "" or _texture_cache.has(path) or _texture_load_requests.has(path):
		return
	if not ResourceLoader.exists(path):
		return

	# iOS GL Compatibility: threaded load is unreliable for .webp
	if OS.get_name() == "iOS":
		var tex: Texture2D = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		if tex != null:
			_texture_cache[path] = tex
		return

	var error: = ResourceLoader.load_threaded_request(
		path, 
		"", 
		false, 
		ResourceLoader.CACHE_MODE_IGNORE
	)
	if error != OK:
		push_warning("CutscenePlayer: Failed to request threaded texture load (%d): %s" % [error, path])
		return
	_texture_load_requests[path] = true
	_complete_texture_request(path)

func _complete_texture_request(path: String) -> void :
	while _texture_load_requests.has(path) and is_inside_tree():
		var status: = ResourceLoader.load_threaded_get_status(path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var texture: = ResourceLoader.load_threaded_get(path) as Texture2D
				_texture_load_requests.erase(path)
				if texture != null and _texture_keep_paths.has(path):
					_texture_cache[path] = texture
				return
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_texture_load_requests.erase(path)
				return
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame

func _load_crop_metadata() -> void :
	_load_crop_metadata_file(OFFSET_CSV_PATH, true)
	_load_crop_metadata_file(GENERATED_CENSOR_OFFSET_CSV_PATH, false)

func _load_crop_metadata_file(path: String, warn_if_missing: bool) -> void :
	if not FileAccess.file_exists(path):
		if warn_if_missing:
			push_warning("CutscenePlayer: Offset CSV not found: %s" % path)
		return

	var file: = FileAccess.open(path, FileAccess.READ)
	var header_row: = file.get_csv_line()
	var header: = _build_header_map(header_row)

	while not file.eof_reached():
		var row: = file.get_csv_line()
		if row.size() < header_row.size():
			continue

		var filename: = _get_csv_cell(row, header, "filename")
		if filename == "":
			continue

		_crop_metadata[filename] = {
			"off_x": float(_get_csv_cell(row, header, "offset_x", "0.0")), 
			"off_y": float(_get_csv_cell(row, header, "offset_y", "0.0")), 
			"o_w": float(_get_csv_cell(row, header, "original_width", str(REF_WIDTH))), 
			"o_h": float(_get_csv_cell(row, header, "original_height", str(REF_HEIGHT))), 
			"c_w": float(_get_csv_cell(row, header, "cropped_width", "0.0")), 
			"c_h": float(_get_csv_cell(row, header, "cropped_height", "0.0")), 
		}

func _process_image_transition(data: Dictionary) -> void :
	var file_name: = String(data.get("file", ""))
	var layer_index: = int(data.get("layer", 0))
	if not _is_censor_file(file_name):
		await _prepare_mosaic_overlays_for_base_change(file_name, layer_index)
	var censor_base_file: = _find_base_file_for_censor_layer(layer_index) if _is_censor_file(file_name) else ""
	var tex_rect: TextureRect = await _create_base_texture_rect(file_name, censor_base_file)
	if tex_rect == null:
		return

	_apply_mosaic_if_needed(tex_rect, file_name)
	if layer_index > 0:
		tex_rect.name = _get_layer_slot_name(layer_index)
		var existing_node: = cut_container.get_node_or_null(NodePath(str(tex_rect.name)))
		if existing_node:
			existing_node.free()
	else:
		tex_rect.name = file_name

	tex_rect.set_meta("source_file", file_name)
	tex_rect.set_meta("censor_base_file", censor_base_file)
	tex_rect.set_meta("layer", layer_index)
	tex_rect.z_index = layer_index if layer_index > 0 else int(data.get("z", 0))

	var trans_type: = String(data.get("trans", "instant"))
	var duration: = float(data.get("dur", 0.0))
	var viewport_size: = get_viewport().get_visible_rect().size
	var target_pos: = tex_rect.position
	_current_tex_rect = tex_rect
	_current_target_pos = target_pos

	match trans_type:
		"fade":
			tex_rect.modulate.a = 0.0
			cut_container.add_child(tex_rect)
			_current_tween = create_tween()
			_current_tween.tween_property(tex_rect, "modulate:a", 1.0, duration)
			_is_event_skippable = true
			_skip_armed_frame = Engine.get_process_frames()
			await _wait_for_tween_or_click()
		"slide":
			var start_pos: = target_pos
			match String(data.get("dir", "left")):
				"left":
					start_pos.x -= viewport_size.x
				"right":
					start_pos.x += viewport_size.x
				"top":
					start_pos.y -= viewport_size.y
				"bottom":
					start_pos.y += viewport_size.y
			tex_rect.position = start_pos
			cut_container.add_child(tex_rect)
			_current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_current_tween.tween_property(tex_rect, "position", target_pos, duration)
			_is_event_skippable = true
			_skip_armed_frame = Engine.get_process_frames()
			await _wait_for_tween_or_click()
		_:
			cut_container.add_child(tex_rect)

	if not _is_censor_file(file_name):
		await _refresh_censor_layers_for_base_change(layer_index)
	_current_tex_rect = null

func _process_replace_event(data: Dictionary) -> void :
	var layer_index: = int(data.get("layer", 0))
	if layer_index > 0:
		await _replace_layer_image(layer_index, String(data.get("new_file", "")))
		return

	var old_file: = String(data.get("old_file", ""))
	var new_file: = String(data.get("new_file", ""))
	var old_node: TextureRect = null
	for child in cut_container.get_children():
		if child is TextureRect and (String(child.name) == old_file or String(child.get_meta("source_file", "")) == old_file):
			old_node = child as TextureRect
			break

	var inherit_z: = old_node.z_index if old_node else 0
	if new_file == "":
		if old_node:
			old_node.free()
		return

	if not _is_censor_file(new_file):
		await _prepare_mosaic_overlays_for_base_change(new_file, 0)
	var censor_base_file: = _find_base_file_for_censor_layer(0) if _is_censor_file(new_file) else ""
	var tex_rect: TextureRect = await _create_base_texture_rect(new_file, censor_base_file)
	if tex_rect == null:
		return
	if old_node:
		old_node.free()
	_apply_mosaic_if_needed(tex_rect, new_file)
	tex_rect.name = new_file
	tex_rect.z_index = inherit_z
	tex_rect.set_meta("source_file", new_file)
	tex_rect.set_meta("censor_base_file", censor_base_file)
	tex_rect.set_meta("layer", 0)
	cut_container.add_child(tex_rect)
	if not _is_censor_file(new_file):
		await _refresh_censor_layers_for_base_change(0)

func _replace_layer_image(layer_index: int, new_file: String) -> void :
	var slot_name: = _get_layer_slot_name(layer_index)
	var existing_node: = cut_container.get_node_or_null(NodePath(slot_name))
	if new_file == "":
		if existing_node:
			existing_node.free()
		return

	if not _is_censor_file(new_file):
		await _prepare_mosaic_overlays_for_base_change(new_file, layer_index)
	var censor_base_file: = _find_base_file_for_censor_layer(layer_index) if _is_censor_file(new_file) else ""
	var tex_rect: TextureRect = await _create_base_texture_rect(new_file, censor_base_file)
	if tex_rect == null:
		return
	if existing_node:
		existing_node.free()
	_apply_mosaic_if_needed(tex_rect, new_file)
	tex_rect.name = slot_name
	tex_rect.z_index = layer_index
	tex_rect.set_meta("source_file", new_file)
	tex_rect.set_meta("censor_base_file", censor_base_file)
	tex_rect.set_meta("layer", layer_index)
	cut_container.add_child(tex_rect)
	if not _is_censor_file(new_file):
		await _refresh_censor_layers_for_base_change(layer_index)

func _process_remove_event(data: Dictionary) -> void :
	var layer_index: = int(data.get("layer", 0))
	if layer_index > 0:
		var layer_node: = cut_container.get_node_or_null(NodePath(_get_layer_slot_name(layer_index)))
		if layer_node:
			layer_node.free()
		return

	var target_file: = String(data.get("target_file", ""))
	if target_file == "":
		return
	for child in cut_container.get_children():
		if String(child.name) == target_file or String(child.get_meta("source_file", "")) == target_file:
			child.free()
			return

func _process_wait_event(time: float) -> void :
	if time <= 0.0:
		return
	_is_event_skippable = true
	_skip_armed_frame = Engine.get_process_frames()
	_current_tween = create_tween()
	_current_tween.tween_interval(time)
	await _wait_for_tween_or_click()

func _process_wait_click_event(time: float) -> void :
	_is_event_skippable = true
	_skip_armed_frame = Engine.get_process_frames()
	if GlobalVar.dialogue_progression_index > 0 and time > 0.0:
		_current_tween = create_tween()
		_current_tween.tween_interval(time)
		_current_tween.finished.connect(
			func():
				if _is_event_skippable:
					event_skipped.emit()
		)
	await event_skipped
	_is_event_skippable = false
	_current_tween = null

func _wait_for_tween_or_click() -> void :
	if _current_tween:
		_current_tween.finished.connect(
			func():
				if _is_event_skippable:
					event_skipped.emit()
		)
		await event_skipped
	_is_event_skippable = false
	_current_tween = null

func _process_sfx_event(data: Dictionary) -> void :
	var file_name: = String(data.get("file", ""))
	var path: = _find_se_path(file_name)
	if path == "":
		return

	var _offset: = maxf(float(data.get("offset", 0.0)), 0.0)
	if not bool(data.get("wait", false)):
		_play_sfx_after_offset(path, _offset)
		return

	if _offset > 0.0:
		await get_tree().create_timer(_offset).timeout
		if is_skipped:
			return

	var player: = AudioManager.play_any_sfx(load(path))
	if player == null:
		return
	_track_active_sfx_player(player)

	_is_event_skippable = true
	_skip_armed_frame = Engine.get_process_frames()
	player.finished.connect(
		func():
			if _is_event_skippable:
				event_skipped.emit()
	)
	await event_skipped
	_is_event_skippable = false

func _play_sfx_after_offset(path: String, _offset: float) -> void :
	if _offset > 0.0:
		await get_tree().create_timer(_offset).timeout
		if is_skipped:
			return

	var player: = AudioManager.play_any_sfx(load(path))
	_track_active_sfx_player(player)

func _track_active_sfx_player(player: AudioStreamPlayer) -> void :
	if player == null:
		return

	_prune_active_sfx_players()
	_active_sfx_players.append(player)

func _wait_for_active_sfx_after_auto_dialogue() -> void :
	if GlobalVar.dialogue_progression_index <= 0:
		return
	if not dialogue_manager.was_last_line_completed_by_auto():
		return

	_prune_active_sfx_players()
	if _active_sfx_players.is_empty():
		return

	_is_event_skippable = true
	_skip_armed_frame = Engine.get_process_frames()
	while _is_event_skippable and not is_skipped:
		_prune_active_sfx_players()
		if _active_sfx_players.is_empty():
			break
		await get_tree().process_frame
	_is_event_skippable = false

func _prune_active_sfx_players() -> void :
	for index in range(_active_sfx_players.size() - 1, -1, -1):
		var player: AudioStreamPlayer = _active_sfx_players[index]
		if player == null or not is_instance_valid(player) or not player.playing:
			_active_sfx_players.remove_at(index)

func _process_bgm_event(data: Dictionary) -> void :
	var file_name: = String(data.get("file", ""))
	var fade_time: = float(data.get("fade", 0.0))

	if file_name == "" or file_name == "stop":
		AudioManager.stop_bgm(fade_time)
		return

	var path: = _find_bgm_path(file_name)
	if path != "":
		AudioManager.play_any_bgm(load(path))

func _process_final_wait_event() -> void :
	_can_skip_cutscene = false
	_hide_skip_button(true)
	cutscene_title.text = _get_cutscene_title_text()
	_is_in_final_wait = true
	_show_cutscene_title()
	_is_event_skippable = true
	_skip_armed_frame = Engine.get_process_frames()
	await event_skipped
	_is_in_final_wait = false
	_is_event_skippable = false
	_hide_cutscene_title_immediate()

func _create_base_texture_rect(file_name: String, censor_base_file: String = "") -> TextureRect:
	var path: = _get_cutscene_image_path(file_name, censor_base_file)
	if not ResourceLoader.exists(path):
		push_warning("CutscenePlayer: Image not found: %s" % path)
		return null

	var texture: Texture2D = await _load_cutscene_texture(path)
	if texture == null:
		return null

	var tex_rect: = TextureRect.new()
	tex_rect.texture = texture
	tex_rect.set_meta("resolved_path", path)

	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.z_as_relative = false

	var meta_key: = path.get_file()
	if meta_key.get_extension() == "":
		meta_key += ".webp"
	_apply_cutscene_texture_layout(tex_rect, meta_key)

	return tex_rect

func _apply_cutscene_texture_layout(tex_rect: TextureRect, meta_key: String) -> void :
	var screen_size: = get_viewport().get_visible_rect().size
	var crop_data: Dictionary = _get_crop_metadata_for_texture(meta_key, tex_rect.texture)
	if not crop_data.is_empty():
		var data: Dictionary = crop_data
		var original_width: float = maxf(float(data.get("o_w", REF_WIDTH)), 1.0)
		var original_height: float = maxf(float(data.get("o_h", REF_HEIGHT)), 1.0)
		var scale_x: = screen_size.x / original_width
		var scale_y: = screen_size.y / original_height
		tex_rect.size = Vector2(float(data["c_w"]) * scale_x, float(data["c_h"]) * scale_y)
		tex_rect.position = Vector2(float(data["off_x"]) * scale_x, float(data["off_y"]) * scale_y)
	else:
		tex_rect.size = screen_size
		tex_rect.position = Vector2.ZERO

	tex_rect.flip_h = false
	if _should_flip_cutscene_h():
		tex_rect.flip_h = true
		tex_rect.position.x = screen_size.x - tex_rect.position.x - tex_rect.size.x

func _get_crop_metadata_for_texture(meta_key: String, texture: Texture2D) -> Dictionary:
	if _crop_metadata.has(meta_key):
		return _crop_metadata[meta_key]

	var fallback_data: Dictionary = _build_pair_overlay_crop_metadata(meta_key, texture)
	if not fallback_data.is_empty():
		_crop_metadata[meta_key] = fallback_data
	return fallback_data

func _build_pair_overlay_crop_metadata(meta_key: String, texture: Texture2D) -> Dictionary:
	if texture == null or not meta_key.contains("__"):
		return {}

	var parts: = meta_key.split("__", false, 1)
	if parts.size() < 2:
		return {}

	var censor_key: = _normalize_cutscene_image_file_name(parts[1])
	if not _crop_metadata.has(censor_key):
		return {}

	var censor_data: Dictionary = _crop_metadata[censor_key]
	var texture_size: Vector2 = texture.get_size()
	var censor_width: = float(censor_data.get("c_w", texture_size.x))
	var censor_height: = float(censor_data.get("c_h", texture_size.y))
	var padding_x: float = maxf((texture_size.x - censor_width) * 0.5, 0.0)
	var padding_y: float = maxf((texture_size.y - censor_height) * 0.5, 0.0)

	return {
		"off_x": float(censor_data.get("off_x", 0.0)) - padding_x, 
		"off_y": float(censor_data.get("off_y", 0.0)) - padding_y, 
		"o_w": float(censor_data.get("o_w", REF_WIDTH)), 
		"o_h": float(censor_data.get("o_h", REF_HEIGHT)), 
		"c_w": texture_size.x, 
		"c_h": texture_size.y, 
	}

func _load_cutscene_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	_texture_keep_paths[path] = true
	_request_texture_load(path)
	while _texture_load_requests.has(path) and is_inside_tree():
		await get_tree().process_frame

	if not is_inside_tree():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	push_warning("CutscenePlayer: Threaded texture load failed, falling back to sync load: %s" % path)
	var fallback_texture: = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if fallback_texture == null:
		push_warning("CutscenePlayer: Texture load failed: %s" % path)
	else:
		_texture_cache[path] = fallback_texture
	return fallback_texture

func _get_cutscene_image_path(file_name: String, censor_base_file: String = "") -> String:
	var clean_file: = _normalize_cutscene_image_file_name(file_name)
	if clean_file.begins_with("res://"):
		return clean_file
	if _is_censor_file(clean_file):
		return _get_censor_overlay_image_path(clean_file, censor_base_file)
	if GlobalVar.apply_censor:
		var censored_path: = CUTSCENE_CENSORED_IMG_DIR + clean_file
		if ResourceLoader.exists(censored_path):
			return censored_path
	return CUTSCENE_IMG_DIR + clean_file

func _get_censor_overlay_image_path(censor_file: String, censor_base_file: String = "") -> String:
	var pair_file: = _get_pair_censor_file_name(censor_base_file, censor_file)
	if pair_file != "":
		var pair_path: = CUTSCENE_CENSORED_IMG_DIR + pair_file
		if ResourceLoader.exists(pair_path):
			return pair_path

	var generic_path: = CUTSCENE_CENSORED_IMG_DIR + censor_file
	if ResourceLoader.exists(generic_path):
		return generic_path
	if GlobalVar.apply_censor and pair_file != "":
		return CUTSCENE_CENSORED_IMG_DIR + pair_file
	return CUTSCENE_IMG_DIR + censor_file

func _get_pair_censor_file_name(base_file: String, censor_file: String) -> String:
	var clean_base: = _normalize_cutscene_image_file_name(base_file)
	var clean_censor: = _normalize_cutscene_image_file_name(censor_file)
	if clean_base == "" or clean_base.begins_with("res://"):
		return ""
	return "%s__%s" % [clean_base.get_basename(), clean_censor]

func _normalize_cutscene_image_file_name(file_name: String) -> String:
	var clean_file: = file_name.strip_edges()
	if clean_file == "" or clean_file.begins_with("res://"):
		return clean_file
	clean_file = clean_file.get_file()
	if clean_file.get_extension() == "":
		clean_file += ".webp"
	return clean_file

func _is_censor_file(file_name: String) -> bool:
	return _normalize_cutscene_image_file_name(file_name).to_lower().contains("censor")

func _find_base_file_for_censor_layer(censor_layer_index: int) -> String:
	var best_layer: = -1
	var best_file: = ""
	for child in cut_container.get_children():
		if not child is TextureRect:
			continue
		var source_file: = String(child.get_meta("source_file", ""))
		if source_file == "" or _is_censor_file(source_file):
			continue
		var layer_index: = int(child.get_meta("layer", 0))
		if censor_layer_index > 0 and layer_index >= censor_layer_index:
			continue
		if layer_index >= best_layer:
			best_layer = layer_index
			best_file = source_file
	return best_file

func _prepare_mosaic_overlays_for_base_change(base_file: String, base_layer_index: int) -> void :
	if not GlobalVar.apply_censor or GlobalVar.censor_line:
		return
	if base_file == "" or _is_censor_file(base_file):
		return

	var overlay_paths: Array[String] = []
	for child in cut_container.get_children():
		if not child is TextureRect:
			continue
		var source_file: = String(child.get_meta("source_file", ""))
		if not _is_censor_file(source_file):
			continue
		var censor_layer_index: = int(child.get_meta("layer", 0))
		if base_layer_index > 0 and censor_layer_index <= base_layer_index:
			continue
		var censor_base_file: = _find_base_file_after_layer_change(
			censor_layer_index, 
			base_layer_index, 
			base_file
		)
		_append_mosaic_overlay_path(overlay_paths, source_file, censor_base_file)

	for event_index in range(_current_event_index + 1, _events.size()):
		var event: Dictionary = _events[event_index]
		var event_file: = ""
		var event_type: = String(event.get("type", ""))
		if event_type == "image":
			event_file = String(event.get("file", ""))
		elif event_type == "replace":
			event_file = String(event.get("new_file", ""))
		else:
			break
		if not _is_censor_file(event_file):
			break
		var upcoming_censor_layer_index: = int(event.get("layer", 0))
		var upcoming_censor_base_file: = _find_base_file_after_layer_change(
			upcoming_censor_layer_index, 
			base_layer_index, 
			base_file
		)
		_append_mosaic_overlay_path(overlay_paths, event_file, upcoming_censor_base_file)

	for path in overlay_paths:
		_texture_keep_paths[path] = true
		_request_texture_load(path)
	for path in overlay_paths:
		await _load_cutscene_texture(path)

func _find_base_file_after_layer_change(
	censor_layer_index: int, 
	changed_layer_index: int, 
	changed_base_file: String
) -> String:
	var best_layer: = -1
	var best_file: = ""
	for child in cut_container.get_children():
		if not child is TextureRect:
			continue
		var source_file: = String(child.get_meta("source_file", ""))
		if source_file == "" or _is_censor_file(source_file):
			continue
		var layer_index: = int(child.get_meta("layer", 0))
		if layer_index == changed_layer_index:
			continue
		if censor_layer_index > 0 and layer_index >= censor_layer_index:
			continue
		if layer_index >= best_layer:
			best_layer = layer_index
			best_file = source_file

	if censor_layer_index <= 0 or changed_layer_index < censor_layer_index:
		if changed_layer_index >= best_layer:
			best_file = changed_base_file
	return best_file

func _append_mosaic_overlay_path(paths: Array[String], censor_file: String, base_file: String) -> void :
	if censor_file == "" or base_file == "":
		return
	var path: = _get_cutscene_image_path(censor_file, base_file)
	if ResourceLoader.exists(path) and not paths.has(path):
		paths.append(path)

func _refresh_censor_layers_for_base_change(base_layer_index: int) -> void :
	for child in cut_container.get_children():
		if not child is TextureRect:
			continue
		var tex_rect: = child as TextureRect
		var source_file: = String(tex_rect.get_meta("source_file", ""))
		if not _is_censor_file(source_file):
			continue
		var censor_layer_index: = int(tex_rect.get_meta("layer", 0))
		if base_layer_index > 0 and censor_layer_index <= base_layer_index:
			continue
		var censor_base_file: = _find_base_file_for_censor_layer(censor_layer_index)
		if censor_base_file == "":
			continue
		var path: = _get_cutscene_image_path(source_file, censor_base_file)
		if not ResourceLoader.exists(path):
			push_warning("CutscenePlayer: Refreshed censor overlay not found for %s on %s: %s" % [source_file, censor_base_file, path])
			continue
		var texture: Texture2D = await _load_cutscene_texture(path)
		if texture == null:
			continue
		tex_rect.texture = texture
		_apply_cutscene_texture_layout(tex_rect, path.get_file())
		tex_rect.set_meta("resolved_path", path)
		tex_rect.set_meta("censor_base_file", censor_base_file)
		_apply_mosaic_if_needed(tex_rect, source_file)

func _find_bgm_path(file_name: String) -> String:
	if _bgm_path_cache.has(file_name):
		return _bgm_path_cache[file_name]

	var clean_file: = file_name.strip_edges()
	var candidates: Array[String] = []
	if clean_file.begins_with("res://"):
		candidates.append(clean_file)
	elif clean_file.get_extension() != "":
		candidates.append(BGM_DIR + clean_file)
	else:
		for ext in [".tres", ".ogg", ".mp3", ".wav"]:
			candidates.append(BGM_DIR + clean_file + ext)

	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			_bgm_path_cache[file_name] = candidate
			return candidate

	push_warning("CutscenePlayer: BGM not found: %s" % file_name)
	return ""

func _find_se_path(file_name: String) -> String:
	if _se_path_cache.has(file_name):
		return _se_path_cache[file_name]

	var clean_file: = file_name.strip_edges()
	if clean_file == "":
		return ""
	if clean_file.begins_with("res://") and ResourceLoader.exists(clean_file):
		_se_path_cache[file_name] = clean_file
		return clean_file

	for candidate in _get_se_path_candidates(clean_file):
		if ResourceLoader.exists(candidate):
			_se_path_cache[file_name] = candidate
			return candidate

	push_warning("CutscenePlayer: SFX not found: %s" % file_name)
	return ""

func _get_se_path_candidates(clean_file: String) -> Array[String]:
	var candidates: Array[String] = []
	var has_extension: bool = clean_file.get_extension() != ""
	for dir in SE_SEARCH_DIRS:
		if has_extension:
			candidates.append(dir + clean_file)
		else:
			for ext in [".tres", ".ogg", ".mp3", ".wav"]:
				candidates.append(dir + clean_file + ext)

	return candidates

func _apply_mosaic_if_needed(tex_rect: TextureRect, file_name: String) -> void :
	tex_rect.material = null
	if not _is_censor_file(file_name) or GlobalVar.censor_line or GlobalVar.apply_censor:
		return
	if _mosaic_shader == null and ResourceLoader.exists(MOSAIC_SHADER_PATH):
		_mosaic_shader = load(MOSAIC_SHADER_PATH)
	if _mosaic_shader == null:
		return
	var material: = ShaderMaterial.new()
	material.shader = _mosaic_shader
	tex_rect.material = material

func _clear_all_images() -> void :
	for child in cut_container.get_children():
		cut_container.remove_child(child)
		child.free()

func _on_cutscene_all_finished() -> void :
	set_process_input(false)
	set_process_unhandled_input(false)
	_can_skip_cutscene = false
	_hide_skip_button(true)
	cutscene_finished.emit()

	if GlobalVar.chained_cutscene_id != "":
		GlobalVar.play_cutscene_id = GlobalVar.chained_cutscene_id
		GlobalVar.chained_cutscene_id = ""
		_apply_cutscene_iris_wipe_mask(GlobalVar.play_cutscene_id)
		SceneTransition.change_scene(CUTSCENE_PLAYER_SCENE, SceneTransition.TransitionType.IRIS_CENTER, 0.5)
		return

	if GlobalVar.auto_transition_after_cutscene != "":
		var target: = GlobalVar.auto_transition_after_cutscene
		GlobalVar.auto_transition_after_cutscene = ""
		_apply_cutscene_iris_wipe_mask(_cutscene_id)
		SceneTransition.change_scene(target, SceneTransition.TransitionType.IRIS_CENTER, GlobalVar.last_transition_duration)
