extends Control

const ACTIVE_BUTTON_ALPHA: = 1.0
const DISABLED_BUTTON_ALPHA: = 0.2
const ITEM_NAME_PREFIX: = "Item"
const FINAL_TEXT_BLANK_LINE_FONT_SIZE: = 16
const MOBILE_PLATFORMS: Array[String] = ["Android", "iOS"]

@export_group("Sound Settings")
@export var page_change_sfx: Resource

@onready var next_button: BaseButton = $Next
@onready var prev_button: BaseButton = $Prev

@onready var final_text: RichTextLabel = $Item6 / Text

var _items: Array[CanvasItem] = []
var _current_item_index: = 0

func _ready() -> void :
	_collect_items()
	_connect_buttons()
	_update_final_text()
	_show_item(0)

func _notification(what: int) -> void :
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready() and visible:
		_show_item(0)
	elif what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_final_text()

func _input(event: InputEvent) -> void :
	if not is_visible_in_tree() or not _is_pc_environment():
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.echo:
		return

	if event.is_action_pressed("ui_left"):
		_show_prev_item()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_show_next_item()
		get_viewport().set_input_as_handled()

func _collect_items() -> void :
	_items.clear()
	for child in get_children():
		var canvas_item: CanvasItem = child as CanvasItem
		if canvas_item == null:
			continue
		var item_index: int = _get_item_index(canvas_item.name)
		if item_index <= 0:
			continue
		_items.append(canvas_item)

	_items.sort_custom(Callable(self, "_sort_items_by_name_index"))

func _connect_buttons() -> void :
	if not prev_button.pressed.is_connected(_on_prev_pressed):
		prev_button.pressed.connect(_on_prev_pressed)
	if not next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.connect(_on_next_pressed)

func _on_prev_pressed() -> void :
	_show_prev_item()

func _on_next_pressed() -> void :
	_show_next_item()

func _show_prev_item() -> bool:
	_normalize_current_item_index()
	if not _has_prev_item():
		_update_navigation_buttons()
		return false

	return _show_item(_current_item_index - 1, true)

func _show_next_item() -> bool:
	_normalize_current_item_index()
	if not _has_next_item():
		_update_navigation_buttons()
		return false

	return _show_item(_current_item_index + 1, true)

func _show_item(item_index: int, should_play_sfx: bool = false) -> bool:
	if _items.is_empty():
		_current_item_index = 0
		_update_navigation_buttons()
		return false

	_normalize_current_item_index()
	if item_index < 0 or item_index >= _items.size():
		_update_navigation_buttons()
		return false

	var next_index: int = item_index
	if next_index == _current_item_index and should_play_sfx:
		return false

	_current_item_index = next_index
	for index in range(_items.size()):
		_items[index].visible = index == _current_item_index

	if should_play_sfx and page_change_sfx:
		AudioManager.play_any_sfx(page_change_sfx)

	_update_navigation_buttons()
	return true

func _update_navigation_buttons() -> void :
	_normalize_current_item_index()
	_set_button_enabled(prev_button, _has_prev_item())
	_set_button_enabled(next_button, _has_next_item())

func _set_button_enabled(button: BaseButton, is_enabled: bool) -> void :
	button.disabled = not is_enabled
	button.modulate.a = ACTIVE_BUTTON_ALPHA if is_enabled else DISABLED_BUTTON_ALPHA

func _sort_items_by_name_index(a: CanvasItem, b: CanvasItem) -> bool:
	return _get_item_index(a.name) < _get_item_index(b.name)

func _normalize_current_item_index() -> void :
	if _items.is_empty():
		_current_item_index = 0
		return

	_current_item_index = clampi(_current_item_index, 0, _items.size() - 1)

func _has_prev_item() -> bool:
	return not _items.is_empty() and _current_item_index > 0

func _has_next_item() -> bool:
	return not _items.is_empty() and _current_item_index < _items.size() - 1

func _get_item_index(item_name: StringName) -> int:
	var text: = String(item_name)
	if not text.begins_with(ITEM_NAME_PREFIX):
		return 0
	var index_text: = text.substr(ITEM_NAME_PREFIX.length())
	return int(index_text) if index_text.is_valid_int() else 0

func _is_pc_environment() -> bool:
	return OS.get_name() not in MOBILE_PLATFORMS

func _update_final_text() -> void :
	final_text.text = "[left]%s[/left]\n[font_size=%d] [/font_size]\n[right]%s[/right]" % [
		_escape_bbcode(tr("BONUS_6")), 
		FINAL_TEXT_BLANK_LINE_FONT_SIZE, 
		_escape_bbcode(tr("BONUS_NAME")), 
	]

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")
