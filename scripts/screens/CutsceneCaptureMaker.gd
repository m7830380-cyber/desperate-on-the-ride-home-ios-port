extends Node

@export_group("Capture Targets")
@export var capture_intro_static: bool = true
@export var capture_ending_1: bool = true
@export var capture_ending_2: bool = true
@export var capture_ending_3: bool = true
@export var capture_ending_4: bool = true
@export var capture_ending_5: bool = true
@export var capture_ending_6: bool = true
@export var capture_ending_7: bool = true
@export var capture_ending_8: bool = true

@export_group("Capture Languages")
@export var capture_japanese: bool = true
@export var capture_english: bool = true
@export var capture_korean: bool = true
@export var capture_chinese: bool = true

@export_group("Capture Content")
@export var capture_unique_images_without_dialogue: bool = true

@export_group("Capture Settings")
@export var output_base_dir: String = "user://export/"
@export var apply_censor: bool = true
@export var censor_line: bool = true
@export var webp_lossy: bool = false
@export_range(0.0, 1.0, 0.01) var webp_quality: float = 1.0
@export_range(0.0, 1.0, 0.01) var jpeg_quality: float = 0.9

const CAPTURE_SIZE: Vector2i = Vector2i(1080, 1920)
const JPEG_OUTPUT_FOLDER: String = "jpeg"
const JPEG_LINE_OUTPUT_FOLDER: String = "line"
const JPEG_MOSAIC_OUTPUT_FOLDER: String = "mosaic"
const CAPTURE_TARGETS: Array[Dictionary] = [
	{"id": "intro_static", "prefix": 0, "label": "Intro"}, 
	{"id": "ending1", "prefix": 1, "label": "ED1"}, 
	{"id": "ending2", "prefix": 2, "label": "ED2"}, 
	{"id": "ending3", "prefix": 3, "label": "ED3"}, 
	{"id": "ending4", "prefix": 4, "label": "ED4"}, 
	{"id": "ending5", "prefix": 5, "label": "ED5"}, 
	{"id": "ending6", "prefix": 6, "label": "ED6"}, 
	{"id": "ending7", "prefix": 7, "label": "ED7"}, 
	{"id": "ending8", "prefix": 8, "label": "ED8"}, 
]
const HORIZONTAL_FLIP_CUTSCENE_IDS: Array[String] = ["ending6"]
const HORIZONTAL_FLIP_LOCALES: Array[String] = ["ko", "en", "zh"]


const LOCALES: Array[String] = ["ja", "en", "ko", "zh"]


const LOCALE_FOLDER: Dictionary = {"ja": "japanese", "en": "english", "ko": "korean", "zh": "chinese"}


const CUTSCENE_CSV_PATH: = "res://data/cutscenes/%s.csv"
const CUTSCENE_IMG_DIR: = "res://data/images/cutscene/"
const CUTSCENE_CENSORED_IMG_DIR: = "res://data/images/cutscene_censored/"
const OFFSET_CSV_PATH: = "res://data/cutscenes/cutscene_image_position_offset.csv"
const GENERATED_CENSOR_OFFSET_CSV_PATH: = "res://data/cutscenes/cutscene_censor_overlay_offset.csv"
const MOSAIC_SHADER_PATH = "res://shader/mosaic_censor.gdshader"
const REF_WIDTH: float = 540.0
const REF_HEIGHT: float = 960.0
const MAX_LAYER_INDEX: int = 16



const STRIP_PATTERN = "\\[(w|wait|speed|sfx)(?::[^\\]]*)?\\]|\\[w\\d+\\]|\\[spd\\d+\\]|\\[/?(?:shake|wave|rainbow|sh|wv|shwv)\\d*[^\\]]*\\]"

const FS_SCALE_PATTERN = "\\[fs=([^\\]]+)\\]"


const EFFECT_PRESET_REPLACEMENTS = {

	"[w1]": "[w:0.1]", "[w2]": "[w:0.2]", "[w3]": "[w:0.3]", 
	"[w4]": "[w:0.4]", "[w5]": "[w:0.5]", "[w6]": "[w:0.6]", 
	"[w7]": "[w:0.7]", "[w8]": "[w:0.8]", "[w9]": "[w:0.9]", 
	"[w10]": "[w:1.0]", 

	"[spd1]": "[speed:0.1]", "[spd2]": "[speed:0.2]", "[spd3]": "[speed:0.3]", 
	"[spd4]": "[speed:0.4]", "[spd5]": "[speed:0.5]", "[spd6]": "[speed:0.6]", 
	"[spd7]": "[speed:0.7]", "[spd8]": "[speed:0.8]", "[spd9]": "[speed:0.9]", 
	"[spd10]": "[speed:1.0]", "[spd11]": "[speed:1.1]", "[spd12]": "[speed:1.2]", 
	"[spd13]": "[speed:1.3]", "[spd14]": "[speed:1.4]", "[spd15]": "[speed:1.5]", 
	"[spd16]": "[speed:1.6]", "[spd17]": "[speed:1.7]", "[spd18]": "[speed:1.8]", 
	"[spd19]": "[speed:1.9]", "[spd20]": "[speed:2.0]", 

	"[fs3]": "[fs=0.3]", "[/fs3]": "[/fs]", 
	"[fs4]": "[fs=0.4]", "[/fs4]": "[/fs]", 
	"[fs5]": "[fs=0.5]", "[/fs5]": "[/fs]", 
	"[fs6]": "[fs=0.6]", "[/fs6]": "[/fs]", 
	"[fs7]": "[fs=0.7]", "[/fs7]": "[/fs]", 
	"[fs8]": "[fs=0.8]", "[/fs8]": "[/fs]", 
	"[fs9]": "[fs=0.9]", "[/fs9]": "[/fs]", 
	"[fs10]": "[fs=1.0]", "[/fs10]": "[/fs]", 
	"[fs11]": "[fs=1.1]", "[/fs11]": "[/fs]", 
	"[fs12]": "[fs=1.2]", "[/fs12]": "[/fs]", 
	"[fs13]": "[fs=1.3]", "[/fs13]": "[/fs]", 
	"[fs14]": "[fs=1.4]", "[/fs14]": "[/fs]", 
	"[fs15]": "[fs=1.5]", "[/fs15]": "[/fs]", 
	"[fs20]": "[fs=2.0]", "[/fs20]": "[/fs]", 
	"[fs30]": "[fs=3.0]", "[/fs30]": "[/fs]", 
}




var _crop_metadata: Dictionary = {}
var _texture_cache: Dictionary = {}
var _mosaic_shader: Shader = null
var _rx_strip: RegEx
var _rx_fs_scale: RegEx

var _dialogue_box: TextureRect
var _dialogue_label: RichTextLabel
var _dialogue_box_base_position: = Vector2.ZERO
var _dialogue_box_base_size: = Vector2.ZERO
var _dialogue_label_base_offsets: = Vector4.ZERO
var _dialogue_label_base_normal_font_size: int = 0
var _dialogue_label_base_bold_font_size: int = 0
var _dialogue_label_base_line_separation: int = 0
var _next_indicator_base_offsets: = Vector4.ZERO

var _capture_index: int = 0
var _cutscene_sequence_index: int = 0
var _captured_image_hashes: Dictionary = {}
var _current_cutscene_id: String = ""
var _current_locale: String = ""
var _output_dir: String = ""
var _scene_type: String = ""


@onready var cut_container: Control = $CutContainer
@onready var dialogue_manager_node: DialogueManager = $DialogueManager

func _ready() -> void :

	_dialogue_box = dialogue_manager_node.dialogue_box
	_dialogue_label = dialogue_manager_node.dialogue_label


	_dialogue_box.modulate.a = 0.0
	_dialogue_label.text = ""
	_dialogue_label.visible_characters = -1
	_cache_dialogue_capture_layout()


	_rx_strip = RegEx.new()
	_rx_strip.compile(STRIP_PATTERN)
	_rx_fs_scale = RegEx.new()
	_rx_fs_scale.compile(FS_SCALE_PATTERN)

	_load_crop_metadata()

	await _apply_capture_window_settings()
	_apply_dialogue_capture_layout()


	GlobalVar.apply_censor = apply_censor
	GlobalVar.censor_line = censor_line


	DirAccess.make_dir_recursive_absolute(output_base_dir)


	await get_tree().process_frame


	for target in _get_enabled_capture_targets():
		_cutscene_sequence_index = int(target["prefix"])
		_scene_type = String(target["label"])
		if capture_unique_images_without_dialogue:
			await _run_unique_image_capture(String(target["id"]))
		await _run_all_locales(String(target["id"]))

	print("CutsceneCaptureMaker: All captures done. Quitting.")
	get_tree().quit()

func _apply_capture_window_settings() -> void :
	GlobalVar.fullscreen_enabled = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(CAPTURE_SIZE)
	get_window().size = CAPTURE_SIZE
	get_window().content_scale_size = CAPTURE_SIZE
	await get_tree().process_frame
	await get_tree().process_frame

func _cache_dialogue_capture_layout() -> void :
	_dialogue_box_base_position = _dialogue_box.position
	_dialogue_box_base_size = _dialogue_box.size
	_dialogue_label_base_offsets = _get_control_offsets(_dialogue_label)
	_dialogue_label_base_normal_font_size = _dialogue_label.get_theme_font_size("normal_font_size")
	_dialogue_label_base_bold_font_size = _dialogue_label.get_theme_font_size("bold_font_size")
	_dialogue_label_base_line_separation = _dialogue_label.get_theme_constant("line_separation")
	_next_indicator_base_offsets = _get_control_offsets(dialogue_manager_node.next_indicator)
	var initial_locale_offset: = GlobalVar.get_label_text_y_offset(_dialogue_label)
	_dialogue_label_base_offsets.y -= initial_locale_offset
	_dialogue_label_base_offsets.w -= initial_locale_offset

func _apply_dialogue_capture_layout() -> void :
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var capture_scale: = Vector2(screen_size.x / REF_WIDTH, screen_size.y / REF_HEIGHT)
	var font_scale: = minf(capture_scale.x, capture_scale.y)
	var scaled_normal_font_size: = maxi(1, roundi(_dialogue_label_base_normal_font_size * font_scale))
	var scaled_bold_font_size: = maxi(1, roundi(_dialogue_label_base_bold_font_size * font_scale))
	var scaled_label_offsets: = _scale_offsets(_dialogue_label_base_offsets, capture_scale)
	var locale_offset: = GlobalVar.get_text_y_offset_for_font_size(scaled_normal_font_size, _current_locale)
	scaled_label_offsets.y += locale_offset
	scaled_label_offsets.w += locale_offset

	dialogue_manager_node.scale = Vector2.ONE
	_dialogue_box.position = Vector2(_dialogue_box_base_position.x * capture_scale.x, _dialogue_box_base_position.y * capture_scale.y)
	_dialogue_box.size = Vector2(_dialogue_box_base_size.x * capture_scale.x, _dialogue_box_base_size.y * capture_scale.y)
	_set_control_offsets(_dialogue_label, scaled_label_offsets)
	_set_control_offsets(dialogue_manager_node.next_indicator, _scale_offsets(_next_indicator_base_offsets, capture_scale))
	_dialogue_label.add_theme_font_size_override("normal_font_size", scaled_normal_font_size)
	_dialogue_label.add_theme_font_size_override("bold_font_size", scaled_bold_font_size)
	_dialogue_label.add_theme_constant_override("line_separation", roundi(_dialogue_label_base_line_separation * font_scale))
	dialogue_manager_node.set_dialogue_box_layout_base(_dialogue_box.position, _dialogue_box.size)
	dialogue_manager_node.set_dialogue_child_layout_base(
		Vector2(_dialogue_label.position.x, _dialogue_label.position.y - locale_offset), 
		_dialogue_label.size, 
		dialogue_manager_node.next_indicator.position, 
		dialogue_manager_node.next_indicator.size
	)

func _get_control_offsets(control: Control) -> Vector4:
	return Vector4(control.offset_left, control.offset_top, control.offset_right, control.offset_bottom)

func _set_control_offsets(control: Control, offsets: Vector4) -> void :
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w

func _scale_offsets(offsets: Vector4, scale: Vector2) -> Vector4:
	return Vector4(offsets.x * scale.x, offsets.y * scale.y, offsets.z * scale.x, offsets.w * scale.y)

func _get_enabled_capture_targets() -> Array[Dictionary]:
	var enabled_flags: Array[bool] = [
		capture_intro_static, 
		capture_ending_1, 
		capture_ending_2, 
		capture_ending_3, 
		capture_ending_4, 
		capture_ending_5, 
		capture_ending_6, 
		capture_ending_7, 
		capture_ending_8, 
	]
	var enabled_targets: Array[Dictionary] = []
	for index in range(CAPTURE_TARGETS.size()):
		if enabled_flags[index]:
			enabled_targets.append(CAPTURE_TARGETS[index])
	return enabled_targets

func _run_all_locales(cutscene_id: String) -> void :
	_current_cutscene_id = cutscene_id
	GlobalVar.play_cutscene_id = cutscene_id

	for locale in _get_enabled_capture_locales():
		_current_locale = locale
		TranslationServer.set_locale(locale)
		await get_tree().process_frame
		_apply_dialogue_capture_layout()
		dialogue_manager_node.set_dialogue_box_flip_h(_should_flip_cutscene_h())
		await get_tree().process_frame

		var lang_folder = LOCALE_FOLDER.get(locale, locale)


		_output_dir = output_base_dir + lang_folder + "/"
		DirAccess.make_dir_recursive_absolute(_output_dir)
		_capture_index = 0


		_clear_cut_container()


		var raw_events = _load_cutscene_from_csv(cutscene_id)
		if raw_events.is_empty():
			push_error("CutsceneCaptureMaker: No events for '%s'" % cutscene_id)
			continue


		_preload_textures(raw_events)
		await get_tree().process_frame


		await _run_capture_sequence(raw_events, true, false)

func _run_unique_image_capture(cutscene_id: String) -> void :
	_current_cutscene_id = cutscene_id
	GlobalVar.play_cutscene_id = cutscene_id


	_current_locale = "ja"
	TranslationServer.set_locale(_current_locale)
	dialogue_manager_node.set_dialogue_box_flip_h(false)
	_dialogue_box.modulate.a = 0.0
	await get_tree().process_frame

	var censor_folder: = JPEG_LINE_OUTPUT_FOLDER if censor_line else JPEG_MOSAIC_OUTPUT_FOLDER
	_output_dir = output_base_dir.path_join(JPEG_OUTPUT_FOLDER).path_join(censor_folder) + "/"
	DirAccess.make_dir_recursive_absolute(_output_dir)
	_capture_index = 0
	_captured_image_hashes.clear()
	_clear_cut_container()

	var raw_events: = _load_cutscene_from_csv(cutscene_id)
	if raw_events.is_empty():
		push_error("CutsceneCaptureMaker: No events for '%s'" % cutscene_id)
		return

	_preload_textures(raw_events)
	await get_tree().process_frame
	await _run_capture_sequence(raw_events, false, true)

func _should_flip_cutscene_h() -> bool:
	return (
		_get_cutscene_file_stem(_current_cutscene_id) in HORIZONTAL_FLIP_CUTSCENE_IDS
		and _current_locale in HORIZONTAL_FLIP_LOCALES
	)

func _get_cutscene_file_stem(cutscene_id: String) -> String:
	return cutscene_id.get_file().get_basename().to_lower()

func _get_enabled_capture_locales() -> Array[String]:
	var enabled_flags: Array[bool] = [
		capture_japanese, 
		capture_english, 
		capture_korean, 
		capture_chinese, 
	]
	var enabled_locales: Array[String] = []
	for index in range(LOCALES.size()):
		if enabled_flags[index]:
			enabled_locales.append(LOCALES[index])
	return enabled_locales





func _run_capture_sequence(
	events: Array[Dictionary], 
	capture_dialogue: bool, 
	capture_images_without_dialogue: bool
) -> void :







	var i: int = 0
	while i < events.size():
		var ev = events[i]
		var ev_type = ev.get("type", "")

		match ev_type:
			"image", "replace", "remove":



				while i < events.size() and events[i].get("type", "") in ["image", "replace", "remove"]:
					_apply_image_event(events[i])
					i += 1
				if capture_images_without_dialogue:
					await get_tree().process_frame
					await get_tree().process_frame
					await _capture_frame_no_dialogue()

			"dialogue_start":
				if capture_dialogue:
					dialogue_manager_node.change_dialogue_box(
						String(ev.get("box_file", "")), 
						String(ev.get("direction", ""))
					)
					await get_tree().process_frame


				var block: Array[Dictionary] = []
				i += 1
				while i < events.size() and events[i].get("type", "") != "dialogue_end":
					block.append(events[i])
					i += 1

				i += 1

				if capture_dialogue:
					_dialogue_box.modulate.a = 1.0

				await _process_dialogue_block(
					block, 
					capture_dialogue, 
					capture_images_without_dialogue
				)

				_dialogue_box.modulate.a = 0.0

			"dialogue":
				if capture_dialogue:

					_dialogue_box.modulate.a = 1.0
					await _capture_dialogue_line(ev.get("id", ""))
					_dialogue_box.modulate.a = 0.0
				i += 1

			"dialogue_change":
				if capture_dialogue:
					dialogue_manager_node.change_dialogue_box(
						String(ev.get("box_file", "")), 
						String(ev.get("direction", ""))
					)
					await get_tree().process_frame
				i += 1

			"vfx", "clear":


				if ev_type == "clear":
					_clear_cut_container()
					if capture_images_without_dialogue:
						await get_tree().process_frame
						await _capture_frame_no_dialogue()
				i += 1

			_:

				i += 1



func _process_dialogue_block(
	block: Array[Dictionary], 
	capture_dialogue: bool, 
	capture_images_without_dialogue: bool
) -> void :
	var j: int = 0
	while j < block.size():
		var bev = block[j]
		var btype = bev.get("type", "")

		match btype:
			"image", "replace", "remove":

				if capture_dialogue:
					_dialogue_box.modulate.a = 0.0
				while j < block.size() and block[j].get("type", "") in ["image", "replace", "remove"]:
					_apply_image_event(block[j])
					j += 1
				if capture_images_without_dialogue:
					await get_tree().process_frame
					await get_tree().process_frame
					await _capture_frame_no_dialogue()
				if capture_dialogue:
					_dialogue_box.modulate.a = 1.0

			"dialogue":
				if capture_dialogue:
					await _capture_dialogue_line(bev.get("id", ""))
				j += 1

			"dialogue_start":

				j += 1

			"dialogue_change":
				if capture_dialogue:
					dialogue_manager_node.change_dialogue_box(
						String(bev.get("box_file", "")), 
						String(bev.get("direction", ""))
					)
					await get_tree().process_frame
				j += 1

			"dialogue_end":
				j += 1

			_:

				j += 1





func _apply_image_event(data: Dictionary) -> void :
	match data.get("type", ""):
		"image": _apply_image(data)
		"replace": _apply_replace(data)
		"remove": _apply_remove(data)

func _apply_image(data: Dictionary) -> void :
	var file_name: = String(data.get("file", ""))
	var layer_index = int(data.get("layer", 0))
	var censor_base_file: = _find_base_file_for_censor_layer(layer_index) if _is_censor_file(file_name) else ""
	var tex_rect = _create_base_texture_rect(file_name, censor_base_file)
	if tex_rect == null: return
	_apply_mosaic_if_needed(tex_rect, file_name)

	if layer_index > 0:
		tex_rect.name = _get_layer_slot_name(layer_index)
		var existing = cut_container.get_node_or_null(NodePath(str(tex_rect.name)))
		if existing:
			existing.free()
		tex_rect.z_index = layer_index
	else:
		tex_rect.name = file_name
		tex_rect.z_index = int(data.get("z", 0))
	tex_rect.set_meta("source_file", file_name)
	tex_rect.set_meta("censor_base_file", censor_base_file)
	tex_rect.set_meta("layer", layer_index)

	cut_container.add_child(tex_rect)
	if not _is_censor_file(file_name):
		_refresh_censor_layers_for_base_change(layer_index)

func _apply_replace(data: Dictionary) -> void :
	var layer_index = int(data.get("layer", 0))
	if layer_index > 0:
		if data.get("new_file", "") == "": return
		var slot_name = _get_layer_slot_name(layer_index)
		var layer_node = cut_container.get_node_or_null(NodePath(slot_name))
		var layer_new_file: = String(data.get("new_file", ""))
		var layer_censor_base_file: = _find_base_file_for_censor_layer(layer_index) if _is_censor_file(layer_new_file) else ""
		var new_rect = _create_base_texture_rect(layer_new_file, layer_censor_base_file)
		if new_rect == null: return
		_apply_mosaic_if_needed(new_rect, layer_new_file)
		if layer_node:
			layer_node.free()
		new_rect.name = slot_name
		new_rect.z_index = layer_index
		new_rect.set_meta("source_file", layer_new_file)
		new_rect.set_meta("censor_base_file", layer_censor_base_file)
		new_rect.set_meta("layer", layer_index)
		cut_container.add_child(new_rect)
		if not _is_censor_file(layer_new_file):
			_refresh_censor_layers_for_base_change(layer_index)
		return


	var old_node: Node = null
	for child in cut_container.get_children():
		if child.name == StringName(data.get("old_file", "")) or String(child.get_meta("source_file", "")) == String(data.get("old_file", "")):
			old_node = child
			break
	var inherit_z = old_node.z_index if old_node else 0
	if old_node:
		old_node.free()
	if data.get("new_file", "") == "": return
	var replacement_file: = String(data.get("new_file", ""))
	var replacement_censor_base_file: = _find_base_file_for_censor_layer(0) if _is_censor_file(replacement_file) else ""
	var tex_rect = _create_base_texture_rect(replacement_file, replacement_censor_base_file)
	if tex_rect == null: return
	_apply_mosaic_if_needed(tex_rect, replacement_file)
	tex_rect.name = replacement_file
	tex_rect.z_index = inherit_z
	tex_rect.set_meta("source_file", replacement_file)
	tex_rect.set_meta("censor_base_file", replacement_censor_base_file)
	tex_rect.set_meta("layer", 0)
	cut_container.add_child(tex_rect)
	if not _is_censor_file(replacement_file):
		_refresh_censor_layers_for_base_change(0)

func _apply_remove(data: Dictionary) -> void :
	var layer_index = int(data.get("layer", 0))
	if layer_index > 0:
		var slot_name = _get_layer_slot_name(layer_index)
		var node = cut_container.get_node_or_null(slot_name)
		if node:
			node.free()
		return

	var file_id = data.get("target_file", "")
	if file_id == "": return
	for child in cut_container.get_children():
		if child.name == StringName(file_id) or String(child.get_meta("source_file", "")) == String(file_id):
			child.free()
			return

func _clear_cut_container() -> void :
	for child in cut_container.get_children():
		cut_container.remove_child(child)
		child.free()





func _capture_dialogue_line(d_id: String) -> void :
	if d_id == "":
		return

	var raw_text: String = tr(d_id)
	raw_text = _expand_effect_presets(raw_text)
	raw_text = _expand_font_scale_tags(raw_text)
	raw_text = raw_text.replace("♥", "[color=#ff4444]♥[/color]")
	var display_text: String = _strip_timing_tags(raw_text)

	_dialogue_label.text = display_text
	_dialogue_label.visible_characters = -1

	await get_tree().process_frame
	await get_tree().process_frame
	await _save_screenshot(_build_filename("dl_" + d_id))




func _capture_frame_no_dialogue() -> void :
	if cut_container.get_child_count() == 0:
		return


	_dialogue_box.modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	await _save_unique_jpeg_screenshot()

func _build_filename(_tag: String) -> String:
	_capture_index += 1

	return "%d_%s_%02d.webp" % [_cutscene_sequence_index, _scene_type, _capture_index]

func _save_screenshot(file_name: String) -> void :
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_size() != CAPTURE_SIZE:
		img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var path = _output_dir + file_name
	var err = img.save_webp(path, webp_lossy, webp_quality)
	if err != OK:
		push_error("CutsceneCaptureMaker: Failed to save '%s' (err %d)" % [path, err])
	else:
		print("Saved: " + path)

func _save_unique_jpeg_screenshot() -> void :
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_size() != CAPTURE_SIZE:
		img.resize(CAPTURE_SIZE.x, CAPTURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)

	var image_hash: int = hash(img.get_data())
	if _captured_image_hashes.has(image_hash):
		return
	_captured_image_hashes[image_hash] = true

	_capture_index += 1
	var file_name: = "%d_%s_%02d.jpeg" % [_cutscene_sequence_index, _scene_type, _capture_index]
	var path: = _output_dir + file_name
	var err: = img.save_jpg(path, jpeg_quality)
	if err != OK:
		push_error("CutsceneCaptureMaker: Failed to save '%s' (err %d)" % [path, err])
	else:
		print("Saved: " + path)





func _expand_effect_presets(text: String) -> String:
	var expanded = text
	for key in EFFECT_PRESET_REPLACEMENTS.keys():
		expanded = expanded.replace(key, EFFECT_PRESET_REPLACEMENTS[key])
	return expanded

func _expand_font_scale_tags(text: String) -> String:
	var base_size = _get_dialogue_base_font_size()
	var expanded = ""
	var last_pos = 0
	for m in _rx_fs_scale.search_all(text):
		expanded += text.substr(last_pos, m.get_start() - last_pos)
		var scale_text = m.get_string(1).strip_edges()
		if scale_text.is_valid_float() or scale_text.is_valid_int():
			var scale = float(scale_text)
			if scale > 0.0:
				expanded += "[font_size=%d]" % max(1, int(round(base_size * scale)))
			else:
				expanded += m.get_string(0)
		else:
			expanded += m.get_string(0)
		last_pos = m.get_end()
	expanded += text.substr(last_pos)
	return expanded.replace("[/fs]", "[/font_size]")

func _get_dialogue_base_font_size() -> int:
	var size = _dialogue_label.get_theme_font_size("normal_font_size")
	if size <= 0:
		size = _dialogue_label.get_theme_font_size("font_size")
	if size <= 0:
		size = 40
	return size

func _strip_timing_tags(text: String) -> String:

	return _rx_strip.sub(text, "", true)





func _load_cutscene_from_csv(c_id: String) -> Array[Dictionary]:
	var path: = _get_cutscene_csv_path(c_id)
	var events: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_warning("CutsceneCaptureMaker: CSV not found: %s" % path)
		return events

	var file: = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("CutsceneCaptureMaker: Could not open CSV: %s" % path)
		return events

	var header_row: = file.get_csv_line()
	var h: Dictionary = {}
	for i in header_row.size():
		h[header_row[i].strip_edges().to_lower()] = i

	while not file.eof_reached():
		var row: = file.get_csv_line()
		if row.size() < header_row.size(): continue

		var raw_type: = _get_csv_cell(row, h, "type").to_lower()
		if raw_type == "":
			continue

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

		var path_or_id: = _get_csv_cell(row, h, "path_or_id")
		var event: Dictionary = {"type": type}

		match type:
			"image":
				event["file"] = path_or_id
				event["trans"] = "instant"
				event["dur"] = 0.0
				event["dir"] = _get_csv_cell(row, h, "direction", "left")
				event["z"] = int(_get_csv_cell(row, h, "z_index", "0"))
				if image_layer > 0:
					event["layer"] = image_layer
			"remove":
				if remove_layer > 0:
					event["layer"] = remove_layer
				else:
					event["target_file"] = path_or_id
			"replace":
				if replace_layer > 0:
					event["layer"] = replace_layer
					event["new_file"] = path_or_id
				else:
					var _parts: = path_or_id.split(":")
					event["old_file"] = _parts[0].strip_edges()
					event["new_file"] = _parts[1].strip_edges() if _parts.size() > 1 else ""
			"dialogue":
				event["id"] = path_or_id
			"dialogue_start":
				event["box_file"] = path_or_id
				event["direction"] = _get_csv_cell(row, h, "direction")
			"dialogue_change":
				event["box_file"] = path_or_id
				event["direction"] = _get_csv_cell(row, h, "direction")
			"dialogue_end", "clear", "checkpoint", "final_wait":
				pass
			_:
				pass

		if not _should_skip_for_censor_setting(event):
			events.append(event)

	return events

func _get_cutscene_csv_path(c_id: String) -> String:
	var file_name: = c_id.strip_edges().to_lower()
	if file_name.begins_with("res://"):
		return file_name
	if file_name.get_extension() == "":
		return CUTSCENE_CSV_PATH % file_name
	return "res://data/cutscenes/%s" % file_name

func _get_csv_cell(row: PackedStringArray, header: Dictionary, column_name: String, default_value: String = "") -> String:
	if not header.has(column_name):
		return default_value

	var index: int = int(header[column_name])
	if index < 0 or index >= row.size():
		return default_value

	var value: String = row[index].strip_edges()
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
	var suffix = raw_type.substr(base_type.length()).strip_edges()
	if suffix == "":
		return 0
	var layer_text = suffix
	if suffix.begins_with("{") and suffix.ends_with("}"):
		layer_text = suffix.substr(1, suffix.length() - 2).strip_edges()
	if not layer_text.is_valid_int():
		return 0
	var layer_index = int(layer_text)
	if layer_index > MAX_LAYER_INDEX:
		layer_index = MAX_LAYER_INDEX
	return layer_index if layer_index > 0 else 0

func _get_layer_slot_name(layer_index: int) -> String:
	return "image%d" % layer_index





func _create_base_texture_rect(file_name: String, censor_base_file: String = "") -> TextureRect:
	var path: = _get_cutscene_image_path(file_name, censor_base_file)
	if not ResourceLoader.exists(path):
		push_warning("CutsceneCaptureMaker: Image not found: %s" % path)
		return null

	var tex_rect: = TextureRect.new()
	tex_rect.texture = _load_cutscene_texture(path)
	if tex_rect.texture == null:
		return null
	tex_rect.set_meta("resolved_path", path)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE

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
	var texture: Texture2D = null
	if _texture_cache.has(path):
		if _texture_cache[path] == null:
			_texture_cache[path] = _finish_or_fallback_threaded_texture_load(path)
		texture = _texture_cache[path] as Texture2D
	else:
		texture = load(path) as Texture2D
		if texture != null:
			_texture_cache[path] = texture
	return texture

func _finish_or_fallback_threaded_texture_load(path: String) -> Texture2D:
	var status: = ResourceLoader.load_threaded_get_status(path)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED, ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var threaded_texture: = ResourceLoader.load_threaded_get(path) as Texture2D
			if threaded_texture != null:
				return threaded_texture
		ResourceLoader.THREAD_LOAD_FAILED:
			push_warning("CutsceneCaptureMaker: Threaded texture load failed, falling back to sync load: %s" % path)
		_:
			pass

	var fallback_texture: = load(path) as Texture2D
	if fallback_texture == null:
		push_warning("CutsceneCaptureMaker: Texture load failed: %s" % path)
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

func _apply_mosaic_if_needed(tex_rect: TextureRect, file_name: String) -> void :
	tex_rect.material = null
	if not _is_censor_file(file_name) or GlobalVar.censor_line or GlobalVar.apply_censor:
		return
	if _mosaic_shader == null:
		_mosaic_shader = load(MOSAIC_SHADER_PATH)
	var mat = ShaderMaterial.new()
	mat.shader = _mosaic_shader
	tex_rect.material = mat

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
			push_warning("CutsceneCaptureMaker: Refreshed censor overlay not found for %s on %s: %s" % [source_file, censor_base_file, path])
			continue
		var texture: = _load_cutscene_texture(path)
		if texture == null:
			continue
		tex_rect.texture = texture
		_apply_cutscene_texture_layout(tex_rect, path.get_file())
		tex_rect.set_meta("resolved_path", path)
		tex_rect.set_meta("censor_base_file", censor_base_file)
		_apply_mosaic_if_needed(tex_rect, source_file)





func _load_crop_metadata() -> void :
	_load_crop_metadata_file(OFFSET_CSV_PATH, true)
	_load_crop_metadata_file(GENERATED_CENSOR_OFFSET_CSV_PATH, false)

func _load_crop_metadata_file(path: String, warn_if_missing: bool) -> void :
	if not FileAccess.file_exists(path):
		if warn_if_missing:
			push_warning("CutsceneCaptureMaker: Metadata CSV not found at %s" % path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var header = file.get_csv_line()
	var h: Dictionary = {}
	for i in header.size():
		h[header[i].strip_edges().to_lower()] = i
	while not file.eof_reached():
		var row = file.get_csv_line()
		if row.size() < header.size(): continue
		var filename = row[h["filename"]].strip_edges()
		_crop_metadata[filename] = {
			"off_x": float(row[h["offset_x"]]), 
			"off_y": float(row[h["offset_y"]]), 
			"o_w": float(row[h["original_width"]]), 
			"o_h": float(row[h["original_height"]]), 
			"c_w": float(row[h["cropped_width"]]), 
			"c_h": float(row[h["cropped_height"]]), 
		}





func _preload_textures(events: Array) -> void :
	for e in events:
		var file_name: = ""
		match e.get("type", ""):
			"image": file_name = e.get("file", "")
			"replace": file_name = e.get("new_file", "")
		if file_name.is_empty(): continue
		var path: = _get_cutscene_image_path(file_name)
		if _texture_cache.has(path) or not ResourceLoader.exists(path): continue
		_texture_cache[path] = null
		var error: = ResourceLoader.load_threaded_request(path)
		if error != OK:
			_texture_cache.erase(path)
			push_warning("CutsceneCaptureMaker: Failed to request threaded texture load (%d): %s" % [error, path])
