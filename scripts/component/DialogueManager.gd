extends CanvasLayer
class_name DialogueManager

class DialogueShakeEffect extends RichTextEffect:
	const LEVEL_SCALE: = 0.2625

	var bbcode: = "dshake"

	func _process_custom_fx(char_fx: CharFXTransform) -> bool:
		var rate: = maxf(float(char_fx.env.get("rate", 30.0)), 0.001)
		var level: = float(char_fx.env.get("level", 3.0)) * LEVEL_SCALE
		var _seed: = int(char_fx.env.get("seed", 0))
		var char_index: = int(char_fx.range.x) + int(char_fx.relative_index)
		var time_step: = int(floor(char_fx.elapsed_time * rate))

		var x_hash: = _hash_int(char_index * 73856093 + time_step * 19349663 + _seed)
		var y_hash: = _hash_int(char_index * 83492791 + time_step * 2971215073 + _seed + 17)
		char_fx.offset = Vector2(
			(_unit_from_hash(x_hash) * 2.0 - 1.0) * level, 
			(_unit_from_hash(y_hash) * 2.0 - 1.0) * level
		)
		return true

	func _hash_int(value: int) -> int:
		var x: = value
		x = ((x >> 16) ^ x) * 73244475
		x = ((x >> 16) ^ x) * 73244475
		x = (x >> 16) ^ x
		return x & 2147483647

	func _unit_from_hash(value: int) -> float:
		return float(value % 10000) / 9999.0

const DIALOGUE_BUBBLE_DIR: = "res://data/images/ui/"
const DEFAULT_DIALOGUE_BUBBLE_FILE: = "dialogue_bubble_1.webp"
const DIALOGUE_LABEL_LAYOUT_REFERENCE_BOX_HEIGHT: float = 208.0
const DIALOGUE_LABEL_LAYOUT_BY_BUBBLE: Dictionary = {
	"dialogue_bubble_0_short": Vector2(84.0, 108.0), 
	"dialogue_bubble_1_short": Vector2(84.0, 108.0), 
	"dialogue_bubble_think_1": Vector2(84.0, 108.0), 
	"dialogue_bubble_2_short": Vector2(84.0, 108.0), 
}
const NEXT_INDICATOR_LABEL_BOTTOM_MARGIN: float = 2.0

const AUTO_WAIT_MULTIPLIERS: = {
	"ko": [0.0, 0.12, 0.032], 
	"ja": [0.0, 0.144, 0.04], 
	"en": [0.0, 0.096, 0.024], 
	"zh": [0.0, 0.12, 0.032], 
}

const AUTO_MIN_WAIT: = [0.0, 2.8, 1.2]

const TYPING_SPEED_BY_LOCALE: = {
	"ko": 0.05, 
	"ja": 0.05, 
	"en": 0.035, 
	"zh": 0.05, 
}

const EFFECT_PRESET_REPLACEMENTS: = {
	"[w1]": "[w:0.1]", 
	"[w2]": "[w:0.2]", 
	"[w3]": "[w:0.3]", 
	"[w4]": "[w:0.4]", 
	"[w5]": "[w:0.5]", 
	"[w6]": "[w:0.6]", 
	"[w7]": "[w:0.7]", 
	"[w8]": "[w:0.8]", 
	"[w9]": "[w:0.9]", 
	"[w10]": "[w:1.0]", 
	"[spd1]": "[speed:0.1]", 
	"[spd2]": "[speed:0.2]", 
	"[spd3]": "[speed:0.3]", 
	"[spd4]": "[speed:0.4]", 
	"[spd5]": "[speed:0.5]", 
	"[spd6]": "[speed:0.6]", 
	"[spd7]": "[speed:0.7]", 
	"[spd8]": "[speed:0.8]", 
	"[spd9]": "[speed:0.9]", 
	"[spd10]": "[speed:1.0]", 
	"[spd11]": "[speed:1.1]", 
	"[spd12]": "[speed:1.2]", 
	"[spd13]": "[speed:1.3]", 
	"[spd14]": "[speed:1.4]", 
	"[spd15]": "[speed:1.5]", 
	"[spd16]": "[speed:1.6]", 
	"[spd17]": "[speed:1.7]", 
	"[spd18]": "[speed:1.8]", 
	"[spd19]": "[speed:1.9]", 
	"[spd20]": "[speed:2.0]", 
	"[fs3]": "[fs=0.3]", 
	"[/fs3]": "[/fs]", 
	"[fs4]": "[fs=0.4]", 
	"[/fs4]": "[/fs]", 
	"[fs5]": "[fs=0.5]", 
	"[/fs5]": "[/fs]", 
	"[fs6]": "[fs=0.6]", 
	"[/fs6]": "[/fs]", 
	"[fs7]": "[fs=0.7]", 
	"[/fs7]": "[/fs]", 
	"[fs8]": "[fs=0.8]", 
	"[/fs8]": "[/fs]", 
	"[fs9]": "[fs=0.9]", 
	"[/fs9]": "[/fs]", 
	"[fs10]": "[fs=1.0]", 
	"[/fs10]": "[/fs]", 
	"[fs11]": "[fs=1.1]", 
	"[/fs11]": "[/fs]", 
	"[fs12]": "[fs=1.2]", 
	"[/fs12]": "[/fs]", 
	"[fs13]": "[fs=1.3]", 
	"[/fs13]": "[/fs]", 
	"[fs14]": "[fs=1.4]", 
	"[/fs14]": "[/fs]", 
	"[fs15]": "[fs=1.5]", 
	"[/fs15]": "[/fs]", 
	"[fs20]": "[fs=2.0]", 
	"[/fs20]": "[/fs]", 
	"[fs30]": "[fs=3.0]", 
	"[/fs30]": "[/fs]", 
	"[sh0]": "[dshake rate=10.0 level=2]", 
	"[sh]": "[dshake]", 
	"[/sh]": "[/dshake]", 
	"[sh1]": "[dshake]", 
	"[/sh1]": "[/dshake]", 
	"[sh2]": "[dshake rate=40.0 level=7]", 
	"[/sh2]": "[/dshake]", 
	"[sh3]": "[dshake rate=60.0 level=10]", 
	"[/sh3]": "[/dshake]", 
	"[wv]": "[wave]", 
	"[/wv]": "[/wave]", 
	"[wv0]": "[wave amp=5.0 freq=5.0 connected=1]", 
	"[/wv0]": "[/wave]", 
	"[wv1]": "[wave amp=10.0 freq=5.0 connected=1]", 
	"[/wv1]": "[/wave]", 
	"[wv2]": "[wave amp=20.0 freq=5.0 connected=1]", 
	"[/wv2]": "[/wave]", 
	"[wv3]": "[wave amp=30.0 freq=5.0 connected=1]", 
	"[/wv3]": "[/wave]", 
}

@onready var dialogue_box: TextureRect = $DialogueBox
@onready var dialogue_label: RichTextLabel = $DialogueBox / DialogueLabel
@onready var next_indicator: TextureRect = $DialogueBox / NextIndicator
@onready var type_timer: Timer = $TypeTimer
@onready var wait_timer: Timer = $WaitTimer
@onready var indicator_timer: Timer = $IndicatorTimer

@export var typing_speed: float = 0.05
@export var jump_offset: float = 5.0
@export var balloon_fade_speed: float = 0.2
@export var ui_z_index: int = 100

var auto_timer: Timer = Timer.new()
var _custom_tags: Dictionary = {}
var _temp_speed: float = 0.05
var _indicator_origin_pos: = Vector2.ZERO
var _indicator_base_size: = Vector2.ZERO
var _dialogue_box_base_position: = Vector2.ZERO
var _dialogue_box_base_size: = Vector2.ZERO
var _dialogue_label_base_position: = Vector2.ZERO
var _dialogue_label_base_size: = Vector2.ZERO
var _dialogue_label_base_offsets: = Vector4.ZERO
var _current_dialogue_box_placement: = ""
var _dialogue_box_flip_h: = false
var _is_dialogue_active: = false
var _is_line_pending: = false
var _current_line_id: = ""
var _last_line_completed_by_auto: = false
var _rx_custom_tag: RegEx
var _rx_bbcode_strip: RegEx
var _rx_font_scale: RegEx
var _indicator_tween: Tween
var _current_dialogue_box_texture_path: = ""

signal dialogue_started
signal dialogue_ended
signal dialogue_line_finished(d_id: String)

func _ready() -> void :
	add_child(auto_timer)
	auto_timer.one_shot = true
	auto_timer.timeout.connect(_complete_current_line_by_auto)

	_indicator_base_size = next_indicator.size
	_move_next_indicator_to_label()
	_dialogue_box_base_position = dialogue_box.position
	_dialogue_box_base_size = dialogue_box.size
	_dialogue_label_base_position = dialogue_label.position
	_dialogue_label_base_size = dialogue_label.size
	_dialogue_label_base_offsets = _get_control_offsets(dialogue_label)
	_apply_dialogue_child_placement()

	dialogue_box.z_index = ui_z_index
	dialogue_box.modulate.a = 0.0
	_current_dialogue_box_texture_path = dialogue_box.texture.resource_path if dialogue_box.texture else ""
	dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_label.install_effect(DialogueShakeEffect.new())
	dialogue_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	next_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_label.text = ""
	_hide_next_indicator()

	type_timer.timeout.connect(_on_type_timer_timeout)
	wait_timer.timeout.connect( func(): type_timer.start(_temp_speed))
	indicator_timer.timeout.connect(_on_indicator_timer_timeout)

	_rx_custom_tag = RegEx.new()
	_rx_custom_tag.compile("\\[(w|wait|speed|sfx)(?::([^\\]]*))?\\]")
	_rx_bbcode_strip = RegEx.new()
	_rx_bbcode_strip.compile("\\[[^\\]]+\\]")
	_rx_font_scale = RegEx.new()
	_rx_font_scale.compile("\\[fs=([^\\]]+)\\]")

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_dialogue_child_placement()

func _apply_locale_font_offsets(locale: String) -> void :
	var _offset: float = GlobalVar.get_label_text_y_offset(dialogue_label, locale)
	var offsets: = _get_dialogue_label_layout_offsets()
	offsets.y += _offset
	offsets.w += _offset
	_set_control_offsets(dialogue_label, offsets)

func set_dialogue_box_texture(file_name: String) -> void :
	var path: = _get_dialogue_box_texture_path(file_name)
	if not ResourceLoader.exists(path):
		push_warning("DialogueManager: Dialogue box texture not found: %s" % path)
		return
	if path == _current_dialogue_box_texture_path:
		return
	dialogue_box.texture = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	dialogue_box.queue_redraw()
	_current_dialogue_box_texture_path = path
	_apply_dialogue_child_placement()

func reset_dialogue_box_texture() -> void :
	set_dialogue_box_texture(DEFAULT_DIALOGUE_BUBBLE_FILE)

func set_dialogue_box_layout_base(base_position: Vector2, base_size: Vector2) -> void :
	_dialogue_box_base_position = base_position
	_dialogue_box_base_size = base_size

func set_dialogue_child_layout_base(
	label_position: Vector2, 
	label_size: Vector2, 
	_indicator_position: Vector2, 
	indicator_size: Vector2
) -> void :
	_dialogue_label_base_position = label_position
	_dialogue_label_base_size = label_size
	_dialogue_label_base_offsets = _get_control_offsets(dialogue_label)
	_indicator_base_size = indicator_size
	_apply_dialogue_child_placement()

func set_dialogue_box_placement(direction: String = "") -> void :
	_current_dialogue_box_placement = direction.strip_edges().to_lower()
	_apply_dialogue_box_layout()

func set_dialogue_box_flip_h(should_flip: bool) -> void :
	_dialogue_box_flip_h = should_flip
	_apply_dialogue_box_layout()

func _apply_dialogue_box_layout() -> void :
	if _current_dialogue_box_placement == "upper":
		dialogue_box.position = Vector2(
			_dialogue_box_base_position.x, 
			_get_mirrored_viewport_y(_dialogue_box_base_position.y, _dialogue_box_base_size.y)
		)
		dialogue_box.size = _dialogue_box_base_size
		dialogue_box.flip_h = _dialogue_box_flip_h
		dialogue_box.flip_v = true
		_apply_dialogue_child_placement()
		return

	dialogue_box.position = _dialogue_box_base_position
	dialogue_box.size = _dialogue_box_base_size
	dialogue_box.flip_h = _dialogue_box_flip_h
	dialogue_box.flip_v = false
	_apply_dialogue_child_placement()

func _apply_dialogue_child_placement() -> void :
	_set_control_anchors(dialogue_label, Vector4(0.0, 0.0, 1.0, 0.0))
	_apply_locale_font_offsets(TranslationServer.get_locale().left(2))
	_apply_next_indicator_placement()
	_indicator_origin_pos = next_indicator.position

func _get_dialogue_label_layout_offsets() -> Vector4:
	var label_top: float = _dialogue_label_base_position.y
	var label_height: float = _dialogue_label_base_size.y
	var bubble_name: = _current_dialogue_box_texture_path.get_file().get_basename()
	if DIALOGUE_LABEL_LAYOUT_BY_BUBBLE.has(bubble_name):
		var layout: Vector2 = DIALOGUE_LABEL_LAYOUT_BY_BUBBLE[bubble_name]
		var layout_scale: = _dialogue_box_base_size.y / DIALOGUE_LABEL_LAYOUT_REFERENCE_BOX_HEIGHT
		label_top = layout.x * layout_scale
		label_height = layout.y * layout_scale
	if _current_dialogue_box_placement == "upper":
		var lower_label_global_y: = _dialogue_box_base_position.y + label_top
		var upper_label_global_y: = _get_mirrored_viewport_y(lower_label_global_y, label_height)
		var upper_box_global_y: = _get_mirrored_viewport_y(
			_dialogue_box_base_position.y, 
			_dialogue_box_base_size.y
		)
		label_top = upper_label_global_y - upper_box_global_y
	return Vector4(
		_dialogue_label_base_offsets.x, 
		label_top, 
		_dialogue_label_base_offsets.z, 
		label_top + label_height
	)

func _get_mirrored_viewport_y(original_y: float, height: float) -> float:
	var viewport_rect: = get_viewport().get_visible_rect()
	return viewport_rect.position.y + viewport_rect.end.y - original_y - height

func _apply_next_indicator_placement() -> void :
	_move_next_indicator_to_label()
	var indicator_left: = maxf(0.0, dialogue_label.size.x - _indicator_base_size.x)
	var animation_margin: = maxf(0.0, jump_offset)
	var indicator_top: = maxf(0.0, dialogue_label.size.y - _indicator_base_size.y - NEXT_INDICATOR_LABEL_BOTTOM_MARGIN - animation_margin)
	_set_control_anchors(next_indicator, Vector4(0.0, 0.0, 0.0, 0.0))
	_set_control_offsets(next_indicator, Vector4(
		indicator_left, 
		indicator_top, 
		indicator_left + _indicator_base_size.x, 
		indicator_top + _indicator_base_size.y
	))

func _move_next_indicator_to_label() -> void :
	if next_indicator.get_parent() == dialogue_label:
		return
	var parent: = next_indicator.get_parent()
	if parent:
		parent.remove_child(next_indicator)
	dialogue_label.add_child(next_indicator)

func _get_control_anchors(control: Control) -> Vector4:
	return Vector4(control.anchor_left, control.anchor_top, control.anchor_right, control.anchor_bottom)

func _set_control_anchors(control: Control, anchors: Vector4) -> void :
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w

func _get_control_offsets(control: Control) -> Vector4:
	return Vector4(control.offset_left, control.offset_top, control.offset_right, control.offset_bottom)

func _set_control_offsets(control: Control, offsets: Vector4) -> void :
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w

func _get_dialogue_box_texture_path(file_name: String) -> String:
	var clean_file: = file_name.strip_edges()
	if clean_file == "":
		clean_file = DEFAULT_DIALOGUE_BUBBLE_FILE
	if clean_file.begins_with("res://"):
		return clean_file
	if clean_file.get_extension() == "":
		clean_file += ".webp"
	return DIALOGUE_BUBBLE_DIR + clean_file

func load_extra_metadata(_path: String) -> void :
	pass

func start_dialogue(dialogue_box_file: String = "") -> void :
	if dialogue_box_file.strip_edges() != "":
		set_dialogue_box_texture(dialogue_box_file)
	if _is_dialogue_active:
		return

	_hide_next_indicator()
	dialogue_box.modulate.a = 0.0
	var tween: = create_tween()
	await tween.tween_property(dialogue_box, "modulate:a", 1.0, balloon_fade_speed).finished
	_is_dialogue_active = true
	dialogue_started.emit()

func change_dialogue_box(dialogue_box_file: String = "", direction: String = "") -> void :
	set_dialogue_box_placement(direction)
	if dialogue_box_file.strip_edges() != "":
		set_dialogue_box_texture(dialogue_box_file)

func end_dialogue() -> void :
	if not _is_dialogue_active:
		return

	type_timer.stop()
	wait_timer.stop()
	auto_timer.stop()
	_hide_next_indicator()
	_is_line_pending = false
	_current_line_id = ""
	_last_line_completed_by_auto = false
	var tween: = create_tween()
	await tween.tween_property(dialogue_box, "modulate:a", 0.0, balloon_fade_speed).finished
	dialogue_label.text = ""
	set_dialogue_box_placement()
	_is_dialogue_active = false
	dialogue_ended.emit()

func force_reset() -> void :
	type_timer.stop()
	wait_timer.stop()
	auto_timer.stop()
	_hide_next_indicator()
	_is_line_pending = false
	_current_line_id = ""
	_last_line_completed_by_auto = false
	dialogue_label.text = ""
	dialogue_box.modulate.a = 0.0
	set_dialogue_box_placement()
	_is_dialogue_active = false
	_current_dialogue_box_texture_path = dialogue_box.texture.resource_path if dialogue_box.texture else ""

func play_line(d_id: String) -> void :
	if d_id == "":
		return
	if not _is_dialogue_active:
		await start_dialogue()

	_is_line_pending = true
	_current_line_id = d_id
	_last_line_completed_by_auto = false
	_display_line(d_id)
	await dialogue_line_finished

func _display_line(d_id: String) -> void :
	_hide_next_indicator()

	var raw_text: = tr(d_id)
	raw_text = _expand_effect_presets(raw_text)
	raw_text = _replace_builtin_shake_tags(raw_text)
	raw_text = _expand_font_scale_tags(raw_text)
	raw_text = _colorize_symbols(raw_text)
	var clean_text: = _parse_custom_tags(raw_text)

	var effective_speed: = _get_effective_typing_speed()
	_temp_speed = effective_speed
	dialogue_label.text = clean_text
	dialogue_label.visible_characters = 0
	type_timer.start(effective_speed)

func _get_effective_typing_speed() -> float:
	var locale: = TranslationServer.get_locale().left(2)
	return float(TYPING_SPEED_BY_LOCALE.get(locale, typing_speed))

func _input(event: InputEvent) -> void :
	var mouse_event: = event as InputEventMouseButton
	var is_click: bool = mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	var is_key: bool = event.is_action_pressed("ui_accept")
	if is_click or is_key:
		_attempt_proceed()

func _attempt_proceed() -> void :
	if not _is_line_pending:
		return

	if not type_timer.is_stopped() or not wait_timer.is_stopped():
		_finish_typing()
		return

	if next_indicator.visible:
		if not auto_timer.is_stopped():
			auto_timer.stop()
		_complete_current_line(false)
	else:
		_finish_typing()

func _finish_typing() -> void :
	type_timer.stop()
	wait_timer.stop()
	dialogue_label.visible_characters = -1
	_show_next_indicator()

	var progression_mode: = clampi(GlobalVar.dialogue_progression_index, 0, AUTO_MIN_WAIT.size() - 1)
	if progression_mode > 0:
		_start_auto_progression_wait(progression_mode)

func _start_auto_progression_wait(mode_index: int) -> void :
	var locale: = TranslationServer.get_locale().left(2)
	if not AUTO_WAIT_MULTIPLIERS.has(locale):
		locale = "en"

	var safe_mode: = clampi(mode_index, 1, AUTO_MIN_WAIT.size() - 1)
	var multiplier: = float(AUTO_WAIT_MULTIPLIERS[locale][safe_mode])
	var char_count: = dialogue_label.get_total_character_count()
	var wait_duration: = maxf(float(AUTO_MIN_WAIT[safe_mode]), char_count * multiplier)
	auto_timer.start(wait_duration)

func was_last_line_completed_by_auto() -> bool:
	return _last_line_completed_by_auto

func _complete_current_line_by_auto() -> void :
	_complete_current_line(true)

func _complete_current_line(completed_by_auto: bool = false) -> void :
	if not _is_line_pending:
		return

	var finished_id: = _current_line_id
	_is_line_pending = false
	_current_line_id = ""
	_last_line_completed_by_auto = completed_by_auto
	dialogue_line_finished.emit(finished_id)

func _parse_custom_tags(text: String) -> String:
	_custom_tags.clear()
	var clean_text: = ""
	var last_pos: = 0
	var visible_pos: = 0

	for match_result in _rx_custom_tag.search_all(text):
		var chunk: = text.substr(last_pos, match_result.get_start() - last_pos)
		clean_text += chunk
		visible_pos += _get_visible_length(chunk)

		if not _custom_tags.has(visible_pos):
			_custom_tags[visible_pos] = []
		_custom_tags[visible_pos].append({
			"type": match_result.get_string(1), 
			"value": match_result.get_string(2), 
		})
		last_pos = match_result.get_end()

	clean_text += text.substr(last_pos)
	return clean_text

func _expand_font_scale_tags(text: String) -> String:
	var base_size: = _get_dialogue_base_font_size()
	var expanded: = ""
	var last_pos: = 0

	for match_result in _rx_font_scale.search_all(text):
		expanded += text.substr(last_pos, match_result.get_start() - last_pos)

		var full_tag: = match_result.get_string(0)
		var scale_text: = match_result.get_string(1).strip_edges()
		var replacement: = full_tag
		if scale_text.is_valid_float() or scale_text.is_valid_int():
			var _scale: = float(scale_text)
			if _scale > 0.0:
				var scaled_size: = maxi(1, int(round(base_size * _scale)))
				replacement = "[font_size=%d]" % scaled_size

		expanded += replacement
		last_pos = match_result.get_end()

	expanded += text.substr(last_pos)
	return expanded.replace("[/fs]", "[/font_size]")

func _expand_effect_presets(text: String) -> String:
	var expanded: = text
	for key in EFFECT_PRESET_REPLACEMENTS.keys():
		expanded = expanded.replace(key, EFFECT_PRESET_REPLACEMENTS[key])
	return expanded

func _replace_builtin_shake_tags(text: String) -> String:
	return text.replace("[/shake]", "[/dshake]").replace("[shake", "[dshake")

func _colorize_symbols(text: String) -> String:
	var heart: = String.chr(9829)
	return text.replace(heart, "[color=#ff4444]%s[/color]" % heart)

func _get_dialogue_base_font_size() -> int:
	var base_size: = dialogue_label.get_theme_font_size("normal_font_size")
	if base_size <= 0:
		base_size = dialogue_label.get_theme_font_size("font_size")
	if base_size <= 0:
		base_size = 36
	return base_size

func _get_visible_length(text: String) -> int:
	return _rx_bbcode_strip.sub(text, "", true).length()

func _on_type_timer_timeout() -> void :
	var current_idx: = dialogue_label.visible_characters

	if _custom_tags.has(current_idx):
		var tags: = _custom_tags[current_idx] as Array
		_custom_tags.erase(current_idx)
		if _handle_tags(tags):
			type_timer.stop()
			return

	if dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
		type_timer.wait_time = _temp_speed
	else:
		_finish_typing()

func _handle_tags(tags: Array) -> bool:
	var should_pause: = false
	for tag_entry in tags:
		var tag: = tag_entry as Dictionary
		var tag_type: = String(tag.get("type", ""))
		var tag_value: = String(tag.get("value", ""))
		match tag_type:
			"w", "wait":
				wait_timer.start(float(tag_value) if tag_value != "" else 0.5)
				should_pause = true
			"speed":
				var speed_scale: = float(tag_value) if tag_value != "" else 1.0
				var base_speed: = _get_effective_typing_speed()
				_temp_speed = maxf(0.001, base_speed / speed_scale) if speed_scale > 0.0 else base_speed
	return should_pause

func _on_indicator_timer_timeout() -> void :
	pass

func _show_next_indicator() -> void :
	next_indicator.visible = true
	next_indicator.position = _indicator_origin_pos
	if _indicator_tween:
		_indicator_tween.kill()
	_indicator_tween = create_tween()
	_indicator_tween.set_loops()
	_indicator_tween.tween_property(next_indicator, "position:y", _indicator_origin_pos.y + jump_offset, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_indicator_tween.tween_property(next_indicator, "position:y", _indicator_origin_pos.y, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _hide_next_indicator() -> void :
	next_indicator.visible = false
	indicator_timer.stop()
	if _indicator_tween:
		_indicator_tween.kill()
		_indicator_tween = null
	auto_timer.stop()
	next_indicator.position = _indicator_origin_pos
