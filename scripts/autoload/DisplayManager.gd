extends Node

const FULLSCREEN_OFF: = "OPTION_FULLSCREEN_OFF"
const FULLSCREEN_ON: = "OPTION_FULLSCREEN_ON"
const FULLSCREEN_OPTIONS: Array[String] = [FULLSCREEN_OFF, FULLSCREEN_ON]

const BASELINE_WINDOW_SIZE: = Vector2i(540, 960)
const SOURCE_ASSET_SIZE: = Vector2i(1080, 1920)
const UHD_MIN_SCREEN_HEIGHT: = 2160
const WINDOW_MARGIN: = Vector2i(64, 64)

var available_fullscreen_options: Array[String] = FULLSCREEN_OPTIONS.duplicate()

func _ready() -> void :
	pass

func get_default_fullscreen_enabled() -> bool:
	return false

func get_default_fullscreen_index() -> int:
	return FULLSCREEN_OPTIONS.find(FULLSCREEN_ON) if get_default_fullscreen_enabled() else FULLSCREEN_OPTIONS.find(FULLSCREEN_OFF)


func get_default_resolution_index() -> int:
	return get_default_fullscreen_index()


func apply_resolution(index: int) -> void :
	apply_fullscreen(index == FULLSCREEN_OPTIONS.find(FULLSCREEN_ON))

func apply_fullscreen(enabled: bool) -> void :
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var target_size: = get_windowed_size()
		DisplayServer.window_set_size(target_size)
		_center_window(target_size)

func get_windowed_size() -> Vector2i:
	var screen: = DisplayServer.window_get_current_screen()
	var screen_size: = DisplayServer.screen_get_size(screen)
	var usable_size: = DisplayServer.screen_get_usable_rect(screen).size
	var os_scale: = maxf(DisplayServer.screen_get_scale(screen), 1.0)
	var target_size: = BASELINE_WINDOW_SIZE

	if screen_size.y >= UHD_MIN_SCREEN_HEIGHT:
		target_size = Vector2i(
			maxi(BASELINE_WINDOW_SIZE.x, roundi(SOURCE_ASSET_SIZE.x / os_scale)), 
			maxi(BASELINE_WINDOW_SIZE.y, roundi(SOURCE_ASSET_SIZE.y / os_scale))
		)

	var max_size: = usable_size - WINDOW_MARGIN
	if target_size.x > max_size.x or target_size.y > max_size.y:
		var fit_scale: = minf(float(max_size.x) / target_size.x, float(max_size.y) / target_size.y)
		target_size = Vector2i(roundi(target_size.x * fit_scale), roundi(target_size.y * fit_scale))

	return target_size

func _center_window(target_size: Vector2i) -> void :
	var usable_rect: = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var centered_offset: = Vector2i(
		roundi(float(usable_rect.size.x - target_size.x) / 2.0), 
		roundi(float(usable_rect.size.y - target_size.y) / 2.0)
	)
	var window_pos: = usable_rect.position + centered_offset


	window_pos.x = max(window_pos.x, usable_rect.position.x)
	window_pos.y = max(window_pos.y, usable_rect.position.y)

	DisplayServer.window_set_position(window_pos)
