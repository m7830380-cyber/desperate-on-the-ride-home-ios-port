extends Node


@onready var bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

var transition_duration: float = 1.0
var bgm_tween: Tween



func _ready() -> void :

	add_child(bgm_player)
	add_child(sfx_player)
	bgm_player.bus = "BGM"
	sfx_player.bus = "SFX"




func play_any_bgm(sound: Resource, volume_offset: float = 0.0) -> void :
	if not sound: return

	if sound is SoundData:

		play_bgm_data(sound)
	elif sound is AudioStream:

		play_bgm(sound, volume_offset)


func play_bgm_data(data: SoundData) -> void :
	if not data: return
	play_bgm(data.stream, data.base_volume_db)


func play_bgm(new_stream: AudioStream, volume_offset: float = 0.0) -> void :

	if bgm_tween:
		bgm_tween.kill()


	bgm_player.stop()
	bgm_player.stream = new_stream
	bgm_player.volume_db = 0.0 + volume_offset
	bgm_player.play()


func stop_bgm(custom_duration: float = transition_duration) -> void :
	if bgm_player.playing:
		var tween = create_tween()

		tween.tween_property(bgm_player, "volume_db", -80.0, custom_duration)
		tween.tween_callback(bgm_player.stop)


func stop_sfx(file_name: String, custom_duration: float = 0.3) -> void :
	for child in get_children():
		if child is AudioStreamPlayer and child.bus == "SFX" and child.playing:
			if child.stream and child.stream.resource_path.get_file() == file_name:
				_fade_out_sfx_player(child, custom_duration, child != sfx_player)


func stop_all_sfx(custom_duration: float = 0.3) -> void :
	for child in get_children():
		if child is AudioStreamPlayer and child.bus == "SFX" and child.playing:
			_fade_out_sfx_player(child, custom_duration, child != sfx_player)




func play_any_sfx(sound: Resource) -> AudioStreamPlayer:
	if not sound: return null

	if sound is SoundData:
		return play_sfx_data(sound)
	elif sound is AudioStream:
		return play_sfx(sound)

	return null


func play_sfx_data(data: SoundData) -> AudioStreamPlayer:
	if not data: return null
	return play_sfx(data.stream, data.base_volume_db)


func play_sfx(stream: AudioStream, volume_offset: float = 0.0) -> AudioStreamPlayer:
	if not stream: return null

	var fx_player = AudioStreamPlayer.new()
	add_child(fx_player)

	fx_player.stream = stream
	fx_player.bus = "SFX"
	fx_player.volume_db = volume_offset
	fx_player.play()


	fx_player.finished.connect(fx_player.queue_free)
	return fx_player

func _fade_out_sfx_player(player: AudioStreamPlayer, custom_duration: float, should_free: bool) -> void :
	if custom_duration <= 0.0:
		player.stop()
		if should_free:
			player.queue_free()
		return

	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, custom_duration)
	tween.tween_callback(player.stop)
	if should_free:
		tween.tween_callback(player.queue_free)




func set_volume(bus_name: String, linear_value: float) -> void :

	var db_value = linear_to_db(linear_value)
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, db_value)




func _change_bgm_stream(new_stream: AudioStream, use_fade: bool, volume_offset: float) -> void :
	bgm_player.stream = new_stream
	var target_volume = 0.0 + volume_offset

	if use_fade:
		bgm_player.volume_db = -80.0
		bgm_player.play()
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", target_volume, transition_duration)
	else:
		bgm_player.volume_db = target_volume
		bgm_player.play()
