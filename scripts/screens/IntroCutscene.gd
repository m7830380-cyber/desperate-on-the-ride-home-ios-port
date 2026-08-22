extends CanvasLayer

@onready var bg_far: TextureRect = $BgFar
@onready var bg_med: TextureRect = $BgMed
@onready var bg_near: TextureRect = $BgNear
@onready var car_seat: TextureRect = $Car
@onready var gas_effects: Control = $GasEffects
@onready var gas_emit_origin: Marker2D = $EmitOrigin
@onready var char_portrait: TextureRect = $Char
@onready var car_seat_front: TextureRect = $Char / CarFront
@onready var breathe_effects: Control = $BreatheEffects
@onready var skip_button: TextureButton = $SkipButton
@onready var dialogue_manager: DialogueManager = $DialogueManager

const CUTSCENE_CSV_PATH: String = "res://data/cutscenes/%s.csv"
const CUTSCENE_IMG_DIR: String = "res://data/images/cutscene_common/"
const SE_BASE_DIR: String = "res://data/se/"
const BGM_DIR: String = "res://data/bgm/"
const SE_SEARCH_DIRS: Array[String] = [
	"res://data/se/", 
	"res://data/se/bowel/", 
	"res://data/se/life/", 
	"res://data/se/system/", 
]
const DEFAULT_CUTSCENE_ID: String = "intro"
const NEXT_SCENE_PATH: String = "res://scenes/MiniGame.tscn"
const NEXT_SCENE_TRANSITION_TYPE: int = 1
const NEXT_SCENE_TRANSITION_DURATION: float = 0.8
const SKIP_BUTTON_TRIGGER_RANGE: float = 80.0
const MOBILE_SKIP_BUTTON_TOUCH_MARGIN: float = 20.0
const SKIP_BUTTON_MOVE_DURATION: float = 0.18
const SKIP_BUTTON_INITIAL_VISIBLE_TIME: float = 1.0
const OFFSCREEN_MARGIN: float = 16.0

const FLIPPED_DIRECTION_LOCALES: Array[String] = ["ko", "en", "zh"]

const CAR_SHAKE_MAX_Y: float = 5.0
const CAR_SHAKE_INTERVAL_MIN: float = 0.04
const CAR_SHAKE_INTERVAL_MAX: float = 0.12
const CAR_SHAKE_SMOOTH_SPEED: float = 18.0
const CAR_SHAKE_STDDEV_RATIO: float = 0.33

const GAS_EFFECT_DURATION: float = 4.0
const GAS_EFFECT_FADE_IN_DURATION: float = 0.8
const GAS_EFFECT_FADE_OUT_DURATION: float = 1.2
const BREATHE_EFFECT_FADE_DURATION: float = 2.0

var _events: Array[Dictionary] = []
var _current_event_index: int = 0
var _current_tween: Tween
var _is_event_skippable: bool = false
var _skip_armed_frame: int = -1
var _is_finished: bool = false
var _is_intro_skip_started: bool = false
var _can_skip_intro: bool = false
var _skip_button_tween: Tween = null
var _skip_button_visible: bool = false
var _skip_button_auto_hide_serial: int = 0
var _skip_button_visible_pos: Vector2 = Vector2.ZERO
var _skip_button_hidden_pos: Vector2 = Vector2.ZERO
var _skip_button_activation_rect: Rect2

var _bg_far_neutral_x: float = 0.0
var _bg_med_neutral_x: float = 0.0
var _bg_near_neutral_x: float = 0.0
var _background_direction: float = -1.0
var _is_layout_flipped: bool = false
var _car_seat_base_position: Vector2 = Vector2.ZERO
var _char_portrait_base_position: Vector2 = Vector2.ZERO
var _car_shake_timer: float = 0.0
var _car_shake_next_interval: float = 0.0
var _car_shake_current_y: float = 0.0
var _car_shake_target_y: float = 0.0

var _gas_effect_bag: Array[TextureRect] = []
var _gas_effect_last: TextureRect = null
var _gas_effect_initial_rects: Dictionary = {}
var _gas_effect_tweens: Dictionary = {}
var _breathe_effect_list: Array[TextureRect] = []
var _breathe_effect_current: TextureRect = null
var _breathe_effect_tween: Tween = null
var _breathe_effect_initial_rects: Dictionary = {}

var _se_path_cache: Dictionary = {}
var _bgm_path_cache: Dictionary = {}
var _texture_cache: Dictionary = {}

signal event_skipped
signal intro_finished

func _ready() -> void :
	randomize()
	_bg_far_neutral_x = bg_far.position.x
	_bg_med_neutral_x = bg_med.position.x
	_bg_near_neutral_x = bg_near.position.x
	_car_seat_base_position = car_seat.position
	_char_portrait_base_position = char_portrait.position
	_car_shake_next_interval = randf_range(CAR_SHAKE_INTERVAL_MIN, CAR_SHAKE_INTERVAL_MAX)

	_initialize_gas_effects()
	_initialize_breathe_effects()
	_apply_locale_layout()
	_setup_skip_button()

	_events = _load_cutscene_from_csv(DEFAULT_CUTSCENE_ID)
	if _events.is_empty():
		push_warning("IntroCutscene: No events found for cutscene '%s'." % DEFAULT_CUTSCENE_ID)
	_preload_cutscene_textures(_events)

	call_deferred("_play_intro_cutscene")

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_locale_layout()

func _process(delta: float) -> void :
	_update_background_scroll(delta)
	_update_car_shake(delta)

func _input(event: InputEvent) -> void :
	_handle_skip_button_activation(event)

	if event.is_action_pressed("ui_cancel") and _can_skip_intro:
		_skip_intro()
		return

	var click_position: Vector2 = Vector2.ZERO
	var has_click: bool = false
	var is_mobile_touch: bool = false
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

	var is_key: bool = event.is_action_pressed("ui_accept")
	if has_click and _handle_skip_button_click(click_position, is_mobile_touch):
		get_viewport().set_input_as_handled()
		return

	if not has_click and not is_key:
		return

	if _is_event_skippable and Engine.get_process_frames() > _skip_armed_frame:
		_skip_current_event()

func _setup_skip_button() -> void :
	_skip_button_visible_pos = skip_button.position
	_skip_button_hidden_pos = _get_top_hidden_position(skip_button, _skip_button_visible_pos)
	skip_button.position = _skip_button_hidden_pos
	skip_button.modulate.a = 1.0
	skip_button.disabled = true
	skip_button.visible = false
	_skip_button_visible = false
	_skip_button_activation_rect = Rect2(_skip_button_visible_pos, skip_button.size).grow(SKIP_BUTTON_TRIGGER_RANGE)
	if not skip_button.pressed.is_connected(_on_skip_button_pressed):
		skip_button.pressed.connect(_on_skip_button_pressed)

	_enable_skip_after_transition()

func _enable_skip_after_transition() -> void :
	await get_tree().create_timer(maxf(GlobalVar.last_transition_duration, 0.0)).timeout
	if _is_intro_skip_started or _is_finished:
		return

	_can_skip_intro = true
	_show_skip_button(true)

func _handle_skip_button_activation(event: InputEvent) -> void :
	if not _can_skip_intro or _is_intro_skip_started or _is_finished:
		_hide_skip_button(true)
		return

	var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if motion_event == null:
		return

	if _skip_button_activation_rect.has_point(motion_event.position):
		_show_skip_button()
	elif _skip_button_visible and not skip_button.get_global_rect().has_point(motion_event.position):
		_hide_skip_button()

func _handle_skip_button_click(click_position: Vector2, is_mobile_touch: bool) -> bool:
	if not _can_skip_intro or _is_intro_skip_started or _is_finished:
		return false

	if _skip_button_visible and skip_button.get_global_rect().has_point(click_position):
		_skip_intro()
		return true

	if not is_mobile_touch:
		return false

	var mobile_touch_rect: Rect2 = Rect2(_skip_button_visible_pos, skip_button.size).grow(MOBILE_SKIP_BUTTON_TOUCH_MARGIN)
	if not mobile_touch_rect.has_point(click_position):
		return false

	if not _skip_button_visible:
		_show_skip_button(true)
	return true

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
	if not _can_skip_intro or _is_intro_skip_started or _is_finished:
		return
	_hide_skip_button()

func _on_skip_button_pressed() -> void :
	if _skip_button_visible and _can_skip_intro:
		_skip_intro()

func _get_top_hidden_position(control: Control, visible_pos: Vector2) -> Vector2:
	return Vector2(visible_pos.x, - maxf(control.size.y, 1.0) - OFFSCREEN_MARGIN)

func _is_mobile_platform() -> bool:
	return OS.get_name() in ["Android", "iOS"]

func _skip_intro() -> void :
	if _is_intro_skip_started or _is_finished:
		return

	_is_intro_skip_started = true
	_can_skip_intro = false
	_hide_skip_button()
	if _current_tween:
		_current_tween.kill()
		_current_tween = null
	_is_event_skippable = false
	event_skipped.emit()
	_on_intro_finished()

func _apply_locale_layout() -> void :
	var language: String = TranslationServer.get_locale().get_slice("_", 0)
	var is_flipped: bool = language in FLIPPED_DIRECTION_LOCALES

	_is_layout_flipped = is_flipped
	_background_direction = 1.0 if is_flipped else -1.0
	char_portrait.flip_h = is_flipped
	car_seat.flip_h = is_flipped
	car_seat_front.flip_h = is_flipped
	_set_texture_rect_children_flip(gas_effects, is_flipped)
	_set_texture_rect_children_flip(breathe_effects, is_flipped)
	_apply_effect_group_layout(gas_effects, _gas_effect_initial_rects, true)
	_apply_effect_group_layout(breathe_effects, _breathe_effect_initial_rects, false)
	_reset_background_scroll_positions()

func _set_texture_rect_children_flip(parent: Node, is_flipped: bool) -> void :
	for child in parent.get_children():
		if child is TextureRect:
			var texture_rect: TextureRect = child as TextureRect
			texture_rect.flip_h = is_flipped

func _apply_effect_group_layout(parent: Control, initial_rects: Dictionary, skip_active_gas_effects: bool) -> void :
	for effect in initial_rects.keys():
		if not (effect is TextureRect):
			continue
		if skip_active_gas_effects and _gas_effect_tweens.has(effect):
			continue

		var texture_rect: TextureRect = effect as TextureRect
		var rect: Dictionary = _get_effect_layout_rect(parent, initial_rects[effect])
		texture_rect.position = rect["position"]
		texture_rect.size = rect["size"]

func _get_effect_layout_rect(parent: Control, initial_rect: Dictionary) -> Dictionary:
	var target_position: Vector2 = initial_rect["position"]
	var target_size: Vector2 = initial_rect["size"]

	if _is_layout_flipped:
		target_position.x = parent.size.x - target_position.x - target_size.x

	return {
		"position": target_position, 
		"size": target_size, 
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

func _scroll_background_layer(_layer: TextureRect, neutral_x: float, speed: float, delta: float, direction: float = _background_direction) -> void :
	_layer.position.x += speed * direction * delta

	if direction < 0.0 and _layer.position.x <= neutral_x - GlobalVar.BG_LOOP_WIDTH:
		_layer.position.x = neutral_x
	elif direction > 0.0 and _layer.position.x >= neutral_x:
		_layer.position.x = neutral_x - GlobalVar.BG_LOOP_WIDTH

func _update_car_shake(delta: float) -> void :
	_car_shake_timer += delta

	if _car_shake_timer >= _car_shake_next_interval:
		_car_shake_timer = 0.0
		_car_shake_next_interval = randf_range(CAR_SHAKE_INTERVAL_MIN, CAR_SHAKE_INTERVAL_MAX)
		_car_shake_target_y = _get_random_shake_offset_y()

	_car_shake_current_y = lerpf(_car_shake_current_y, _car_shake_target_y, clampf(delta * CAR_SHAKE_SMOOTH_SPEED, 0.0, 1.0))
	var shake_y: float = roundf(_car_shake_current_y)
	car_seat.position = Vector2(_car_seat_base_position.x, _car_seat_base_position.y + shake_y)
	char_portrait.position = Vector2(_char_portrait_base_position.x, _char_portrait_base_position.y + shake_y)

func _get_random_shake_offset_y() -> float:
	var stddev: float = CAR_SHAKE_MAX_Y * CAR_SHAKE_STDDEV_RATIO
	var magnitude: float = minf(absf(randfn(0.0, stddev)), CAR_SHAKE_MAX_Y)
	return - magnitude

func _play_intro_cutscene() -> void :
	await get_tree().process_frame
	_apply_locale_layout()

	_current_event_index = 0
	while _current_event_index < _events.size():
		if _is_finished:
			return

		var event: Dictionary = _events[_current_event_index]
		match String(event.get("type", "")):
			"image":
				_process_image_event(event)
			"gas":
				await _process_gas_event(event)
			"breathe":
				_start_breathe_effect_loop()
			"wait":
				await _process_wait_event(float(event.get("time", 0.0)))
			"wait_click":
				await _process_wait_click_event(float(event.get("time", 0.0)))
			"sfx":
				await _process_sfx_event(event)
			"sfx_stop":
				AudioManager.stop_sfx(String(event.get("file", "")), float(event.get("fade", 0.3)))
			"bgm":
				_process_bgm_event(event)
			"dialogue_start":
				await dialogue_manager.start_dialogue(String(event.get("box_file", "")))
			"dialogue":
				await dialogue_manager.play_line(String(event.get("id", "")))
			"dialogue_end":
				await dialogue_manager.end_dialogue()
			"final_wait":
				await _process_final_wait_event()

		_current_event_index += 1

	_on_intro_finished()

func _load_cutscene_from_csv(cutscene_id: String) -> Array[Dictionary]:
	var path: String = _get_cutscene_csv_path(cutscene_id)
	var events: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_warning("IntroCutscene: CSV not found: %s" % path)
		return events

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("IntroCutscene: Could not open CSV: %s" % path)
		return events

	var header_row: PackedStringArray = file.get_csv_line()
	var header: Dictionary = _build_header_map(header_row)

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < header_row.size():
			continue

		var event: Dictionary = _parse_cutscene_row(row, header)
		if not event.is_empty():
			events.append(event)

	return events

func _get_cutscene_csv_path(cutscene_id: String) -> String:
	if cutscene_id.begins_with("res://"):
		return cutscene_id

	var file_name: String = cutscene_id.to_lower()
	if file_name.get_extension() == "":
		return CUTSCENE_CSV_PATH % file_name
	return "res://data/cutscenes/%s" % file_name

func _build_header_map(header_row: PackedStringArray) -> Dictionary:
	var header: Dictionary = {}
	for index in range(header_row.size()):
		header[header_row[index].strip_edges().to_lower()] = index
	return header

func _parse_cutscene_row(row: PackedStringArray, header: Dictionary) -> Dictionary:
	var raw_type: String = _get_csv_cell(row, header, "type").to_lower()
	if raw_type == "":
		return {}

	var gas_index: int = _parse_numbered_event_type(raw_type, "gas")
	var type: String = "gas" if gas_index >= 0 else raw_type
	var path_or_id: String = _get_csv_cell(row, header, "path_or_id")
	var event: Dictionary = {"type": type}

	match type:
		"image":
			event["file"] = path_or_id
		"gas":
			event["index"] = gas_index
			event["time"] = float(_get_csv_cell(row, header, "duration", "0.0"))
			event["wait"] = _get_csv_cell(row, header, "wait_flag").to_lower() == "true"
		"breathe":
			pass
		"dialogue_start":
			event["box_file"] = path_or_id
		"dialogue":
			if path_or_id == "":
				push_warning("IntroCutscene: Empty dialogue id. Fill path_or_id or remove this dialogue row.")
				return {}
			event["id"] = path_or_id
		"dialogue_end", "final_wait":
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
			push_warning("IntroCutscene: Unknown event type '%s'." % raw_type)
			return {}

	return event

func _parse_numbered_event_type(raw_type: String, base_type: String) -> int:
	if not raw_type.begins_with(base_type):
		return -1

	var suffix: String = raw_type.substr(base_type.length()).strip_edges()
	if suffix == "":
		return 0
	if suffix.begins_with("{") and suffix.ends_with("}"):
		suffix = suffix.substr(1, suffix.length() - 2).strip_edges()

	return int(suffix) if suffix.is_valid_int() else 0

func _get_csv_cell(row: PackedStringArray, header: Dictionary, column_name: String, default_value: String = "") -> String:
	if not header.has(column_name):
		return default_value

	var index: int = int(header[column_name])
	if index < 0 or index >= row.size():
		return default_value

	var value: String = row[index].strip_edges()
	return default_value if value == "" else value

func _preload_cutscene_textures(events: Array[Dictionary]) -> void :
	for event in events:
		if String(event.get("type", "")) != "image":
			continue

		var file_name: String = String(event.get("file", ""))
		if file_name == "":
			continue

		var path: String = _get_cutscene_image_path(file_name)
		_get_cached_texture(path)

func _process_image_event(data: Dictionary) -> void :
	var file_name: String = String(data.get("file", ""))
	var path: String = _get_cutscene_image_path(file_name)
	var texture: Texture2D = _get_cached_texture(path)
	if texture == null:
		return

	if char_portrait.texture != texture:
		char_portrait.texture = texture

func _get_cached_texture(path: String) -> Texture2D:
	if path == "":
		return null

	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	if not ResourceLoader.exists(path):
		push_warning("IntroCutscene: Image not found: %s" % path)
		return null

	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		push_warning("IntroCutscene: Could not load image: %s" % path)
		return null

	_texture_cache[path] = texture
	return texture

func _process_gas_event(data: Dictionary) -> void :
	var duration: float = float(data.get("time", 0.0))
	if duration <= 0.0:
		duration = GAS_EFFECT_DURATION

	_play_gas_effect(int(data.get("index", 0)), duration)
	if bool(data.get("wait", false)):
		await _process_wait_event(duration)

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
	if time > 0.0:
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

func _process_final_wait_event() -> void :
	_is_event_skippable = true
	_skip_armed_frame = Engine.get_process_frames()
	await event_skipped
	_is_event_skippable = false

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

func _skip_current_event() -> void :
	if _current_tween:
		_current_tween.kill()
		_current_tween = null
	_is_event_skippable = false
	event_skipped.emit()

func _process_sfx_event(data: Dictionary) -> void :
	var file_name: String = String(data.get("file", ""))
	var path: String = _find_se_path(file_name)
	if path == "":
		return

	var _offset: float = maxf(float(data.get("offset", 0.0)), 0.0)
	if not bool(data.get("wait", false)):
		_play_sfx_after_offset(path, _offset)
		return

	if _offset > 0.0:
		await get_tree().create_timer(_offset).timeout
		if _is_finished or _is_intro_skip_started:
			return

	var player: AudioStreamPlayer = AudioManager.play_any_sfx(load(path))
	if player == null:
		return

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
		if _is_finished or _is_intro_skip_started:
			return

	AudioManager.play_any_sfx(load(path))

func _process_bgm_event(data: Dictionary) -> void :
	var file_name: String = String(data.get("file", ""))
	var fade_time: float = float(data.get("fade", 0.0))

	if file_name == "" or file_name == "stop":
		AudioManager.stop_bgm(fade_time)
		return

	var path: String = _find_bgm_path(file_name)
	if path != "":
		AudioManager.play_any_bgm(load(path))

func _initialize_gas_effects() -> void :
	_gas_effect_initial_rects.clear()
	_gas_effect_tweens.clear()
	_gas_effect_bag.clear()
	_gas_effect_last = null

	for child in gas_effects.get_children():
		if child is TextureRect:
			var effect: TextureRect = child as TextureRect
			_gas_effect_initial_rects[effect] = {
				"position": effect.position, 
				"size": effect.size, 
			}
			effect.visible = false
			effect.modulate.a = 0.0

func _play_gas_effect(effect_index: int = 0, duration: float = GAS_EFFECT_DURATION) -> void :
	var effect: TextureRect = _get_gas_effect_by_index(effect_index) if effect_index > 0 else _pop_next_gas_effect()
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
	var fade_in_duration: float = clampf(GAS_EFFECT_FADE_IN_DURATION, 0.0, duration)
	var fade_out_duration: float = clampf(GAS_EFFECT_FADE_OUT_DURATION, 0.0, duration)
	var fade_total_duration: float = fade_in_duration + fade_out_duration
	if fade_total_duration > duration and fade_total_duration > 0.0:
		var fade_scale: float = duration / fade_total_duration
		fade_in_duration *= fade_scale
		fade_out_duration *= fade_scale
	var fade_hold_duration: float = maxf(duration - fade_in_duration - fade_out_duration, 0.0)

	effect.visible = true
	effect.position = start_position
	effect.size = Vector2.ZERO
	effect.modulate.a = 0.0

	var motion_tween: Tween = create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(effect, "position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(effect, "size", target_size, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var fade_tween: Tween = create_tween()
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

func _get_gas_effect_by_index(effect_index: int) -> TextureRect:
	var effect: TextureRect = gas_effects.get_node_or_null("Effect%d" % effect_index) as TextureRect
	if effect != null and _gas_effect_initial_rects.has(effect):
		return effect

	return null

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
		var effect: TextureRect = _gas_effect_bag[index]
		if effect != _gas_effect_last and not effect.visible:
			_swap_gas_effect_bag_item_to_front(index)
			return

	if _gas_effect_last != null and _gas_effect_bag[0] == _gas_effect_last:
		for index in range(1, _gas_effect_bag.size()):
			if _gas_effect_bag[index] != _gas_effect_last:
				_swap_gas_effect_bag_item_to_front(index)
				return

func _swap_gas_effect_bag_item_to_front(index: int) -> void :
	var replacement: TextureRect = _gas_effect_bag[index]
	_gas_effect_bag[index] = _gas_effect_bag[0]
	_gas_effect_bag[0] = replacement

func _initialize_breathe_effects() -> void :
	_breathe_effect_list.clear()
	_breathe_effect_initial_rects.clear()
	_breathe_effect_current = null

	for child in breathe_effects.get_children():
		if child is TextureRect:
			var effect: TextureRect = child as TextureRect
			_breathe_effect_initial_rects[effect] = {
				"position": effect.position, 
				"size": effect.size, 
			}
			effect.visible = false
			effect.modulate.a = 0.0
			_breathe_effect_list.append(effect)

func _start_breathe_effect_loop() -> void :
	if _breathe_effect_list.is_empty() or _breathe_effect_tween != null:
		return

	var effect: TextureRect = _get_random_breathe_effect()
	if effect == null:
		return

	_breathe_effect_current = effect
	effect.visible = true
	effect.modulate.a = 0.0

	_breathe_effect_tween = create_tween()
	_breathe_effect_tween.tween_property(effect, "modulate:a", 1.0, BREATHE_EFFECT_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breathe_effect_tween.tween_callback(_crossfade_breathe_effect)

func _crossfade_breathe_effect() -> void :
	var previous: TextureRect = _breathe_effect_current
	var next: TextureRect = _get_random_breathe_effect(previous)
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

func _get_cutscene_image_path(file_name: String) -> String:
	var clean_file: String = file_name.strip_edges()
	if clean_file.begins_with("res://"):
		return clean_file
	if clean_file.get_extension() == "":
		clean_file += ".webp"
	return CUTSCENE_IMG_DIR + clean_file

func _find_bgm_path(file_name: String) -> String:
	if _bgm_path_cache.has(file_name):
		return _bgm_path_cache[file_name]

	var clean_file: String = file_name.strip_edges()
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

	push_warning("IntroCutscene: BGM not found: %s" % file_name)
	return ""

func _find_se_path(file_name: String) -> String:
	if _se_path_cache.has(file_name):
		return _se_path_cache[file_name]

	var clean_file: String = file_name.strip_edges()
	if clean_file == "":
		return ""
	if clean_file.begins_with("res://") and ResourceLoader.exists(clean_file):
		_se_path_cache[file_name] = clean_file
		return clean_file

	for candidate in _get_se_path_candidates(clean_file):
		if ResourceLoader.exists(candidate):
			_se_path_cache[file_name] = candidate
			return candidate

	push_warning("IntroCutscene: SFX not found: %s" % file_name)
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

func _on_intro_finished() -> void :
	if _is_finished:
		return

	_is_finished = true
	_can_skip_intro = false
	_hide_skip_button(true)
	intro_finished.emit()

	GlobalVar.last_transition_type = NEXT_SCENE_TRANSITION_TYPE
	GlobalVar.last_transition_duration = NEXT_SCENE_TRANSITION_DURATION

	if has_node("/root/SceneTransition"):
		SceneTransition.change_scene(NEXT_SCENE_PATH, NEXT_SCENE_TRANSITION_TYPE, NEXT_SCENE_TRANSITION_DURATION)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
