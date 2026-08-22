extends Node

const FULL_SAVE_PATH: = "user://save_data.cfg"
const TRIAL_SAVE_PATH: = "user://save_data_trial.cfg"
const SAVE_ENCRYPTION_PASSWORD: = "IFYOUCANREADTHISYOUREALLYGOODATFINDINGSECRETS"
const ENDING_SECTION: = "Ending"
const ENDING_COUNT: = 8
const INIT_UNLOCK: = false

var config: = ConfigFile.new()


const SUPPORTED_LOCALES: = ["ko", "ja", "en", "zh"]
const FALLBACK_LOCALE: = "en"

const DEFAULT_SETTINGS: = {
	"bgm_volume": 10, 
	"sfx_volume": 10, 
	"difficulty_index": 0, 
	"dialogue_progression_index": 0, 
	"fullscreen_enabled": false, 
	"locale": "", 
	"censor_line": true, 
}

const RUNTIME_ONLY_SETTINGS: = [
	"apply_censor", 
]

static func _get_default_locale() -> String:
	var sys_locale: = OS.get_locale_language().to_lower()
	return sys_locale if sys_locale in SUPPORTED_LOCALES else FALLBACK_LOCALE

func _ready() -> void :
	load_game()

func load_game() -> void :
	config = ConfigFile.new()
	_load_config_file(_get_save_path())
	_validate_settings()
	_sync_ending_data()
	_apply_to_engine()

func _validate_settings() -> void :
	var modified: = false
	for key in DEFAULT_SETTINGS.keys():
		var current_val = config.get_value("Settings", key, null)
		if current_val == null:
			var val = DEFAULT_SETTINGS[key]
			if key == "locale":
				val = _get_default_locale()
			config.set_value("Settings", key, val)
			modified = true

	for key in RUNTIME_ONLY_SETTINGS:
		if config.has_section_key("Settings", key):
			config.erase_section_key("Settings", key)
			modified = true

	if modified:
		save_game()

func _sync_ending_data() -> void :
	var modified: = false

	for ending_index in range(1, ENDING_COUNT + 1):
		var key: = _get_ending_key(ending_index)
		if not config.has_section_key(ENDING_SECTION, key):
			config.set_value(ENDING_SECTION, key, INIT_UNLOCK)
			modified = true

	if modified:
		save_game()

func _apply_to_engine() -> void :
	GlobalVar.bgm_volume = config.get_value("Settings", "bgm_volume")
	GlobalVar.sfx_volume = config.get_value("Settings", "sfx_volume")
	GlobalVar.difficulty_index = config.get_value("Settings", "difficulty_index")
	GlobalVar.dialogue_progression_index = config.get_value("Settings", "dialogue_progression_index")
	GlobalVar.fullscreen_enabled = config.get_value("Settings", "fullscreen_enabled")

	AudioManager.set_volume("BGM", GlobalVar.bgm_volume / 10.0)
	AudioManager.set_volume("SFX", GlobalVar.sfx_volume / 10.0)

	var saved_locale = config.get_value("Settings", "locale")
	TranslationServer.set_locale(saved_locale)
	GlobalVar.refresh_window_title_deferred()

	GlobalVar.censor_line = config.get_value("Settings", "censor_line")

	if OS.get_name() not in ["Android", "iOS"]:
		DisplayManager.apply_fullscreen(GlobalVar.fullscreen_enabled)

func save_game() -> void :
	config.save_encrypted_pass(_get_save_path(), SAVE_ENCRYPTION_PASSWORD)

func update_setting(key: String, value: Variant) -> void :
	if key in RUNTIME_ONLY_SETTINGS:
		if key == "apply_censor":
			GlobalVar.apply_censor = bool(value)
		return

	config.set_value("Settings", key, value)
	save_game()
	_apply_to_engine()

func is_unlocked(section_name: String, key_type: String) -> bool:
	return config.get_value(section_name, key_type, false)

func is_viewed(section_name: String, key_type: String) -> bool:
	var v_key: = "has_viewed_" + key_type
	return config.get_value(section_name, v_key, false)

func unlock_content(section_name: String, key_type: String) -> void :
	config.set_value(section_name, key_type, true)
	save_game()

func lock_content(section_name: String, key_type: String) -> void :
	config.set_value(section_name, key_type, false)
	var v_key: = "has_viewed_" + key_type
	if config.has_section_key(section_name, v_key):
		config.set_value(section_name, v_key, false)
	save_game()

func mark_as_viewed(section_name: String, key_type: String) -> void :
	var v_key: = "has_viewed_" + key_type
	config.set_value(section_name, v_key, true)
	save_game()

func is_ending_unlocked(ending_index: int) -> bool:
	return config.get_value(ENDING_SECTION, _get_ending_key(ending_index), false)

func unlock_ending(ending_index: int) -> void :
	config.set_value(ENDING_SECTION, _get_ending_key(ending_index), true)
	save_game()

func lock_ending(ending_index: int) -> void :
	config.set_value(ENDING_SECTION, _get_ending_key(ending_index), false)
	save_game()

func _get_ending_key(ending_index: int) -> String:
	return "end%d" % clampi(ending_index, 1, ENDING_COUNT)

func _get_save_path() -> String:
	return TRIAL_SAVE_PATH if GlobalVar.is_trial_version else FULL_SAVE_PATH

func _load_config_file(path: String) -> void :
	var encrypted_error: = config.load_encrypted_pass(path, SAVE_ENCRYPTION_PASSWORD)
	if encrypted_error == OK or encrypted_error == ERR_FILE_NOT_FOUND:
		return

	var plain_config: = ConfigFile.new()
	var plain_error: = plain_config.load(path)
	if plain_error == OK:
		config = plain_config
		save_game()
		return

	push_warning("SaveManager: Failed to load save data. Reinitializing save file: %s" % path)
