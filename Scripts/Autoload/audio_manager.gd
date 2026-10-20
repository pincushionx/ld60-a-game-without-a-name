extends Node

var MusicPlayer : AudioStreamPlayer
var EffectsPlayer : AudioStreamPlayer

var Effects : Dictionary
var Music : Dictionary
const MAX_DISTANCE : float = 100

var music_volume_before_mute : float
var effects_volume_before_mute : float

func _enter_tree():
	MusicPlayer = AudioStreamPlayer.new()
	MusicPlayer.bus = "Music"
	add_child(MusicPlayer)
	
	EffectsPlayer = AudioStreamPlayer.new()
	EffectsPlayer.bus = "Effects"
	add_child(EffectsPlayer)
	
	_loadEffects()
	_loadMusic()
	
	music_volume_before_mute = GetBusVolume("Music")
	effects_volume_before_mute = GetBusVolume("Effects")

func IsMusicMuted() -> bool:
	return GetBusVolume("Music") == 0

func MuteMusic() -> void:
	if music_volume_before_mute > 0:
		music_volume_before_mute = GetBusVolume("Music")
		SetBusVolume("Music", 0)
	
func UnmuteMusic() -> void:
	if music_volume_before_mute > 0:
		SetBusVolume("Music", music_volume_before_mute)

func IsEffectsMuted() -> bool:
	return GetBusVolume("Effects") == 0

func MuteEffects() -> void:
	effects_volume_before_mute = GetBusVolume("Effects")
	SetBusVolume("Effects", 0)

func UnmuteEffects() -> void:
	if effects_volume_before_mute > 0:
		SetBusVolume("Effects", effects_volume_before_mute)

func GetBusVolume(s : String):
	var i : int = AudioServer.get_bus_index(s)
	return db_to_linear (AudioServer.get_bus_volume_db(i))

func SetBusVolume(s : String, level : float):
	var i : int = AudioServer.get_bus_index(s)
	AudioServer.set_bus_volume_db(i, linear_to_db(level))

func _loadMusic():
	var path : String = "res://Audio/Music"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			file_name = file_name.replace(".import", "")
			Music[file_name.get_basename()] = ResourceLoader.load(path + "/" + file_name)
			file_name = dir.get_next()
	else:
		Logs.Error("An error occurred when trying to access the path.")

func _loadEffects():
	var path : String = "res://Audio/Effects"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			file_name = file_name.replace(".import", "")
			Effects[file_name.get_basename()] = ResourceLoader.load(path + "/" + file_name)
			file_name = dir.get_next()
	else:
		Logs.Error("An error occurred when trying to access the path.")

func PlayMusic(s : String):
	if !MusicPlayer.playing:
		var stream : AudioStream = Music[s]
		MusicPlayer.stream = stream
		MusicPlayer.play()

func StopMusic():
	MusicPlayer.stop()
	
func PlayEffect(caller : Node, s : String):
	#if !_fromCurrentRoom(caller):
		#return
	
	
	
	var player = _getPlayerFromCaller(caller)
	
	if Effects[s] is AudioStreamOggVorbis:
		var stream : AudioStreamOggVorbis = Effects[s]
		player.stream = stream
		player.play()
	elif Effects[s] is AudioStreamMP3:
		var stream : AudioStreamMP3 = Effects[s]
		player.stream = stream
		player.play()
	else:
		var stream : AudioStreamWAV = Effects[s]
		player.stream = stream
		player.play()
	#var stream : AudioStream = Effects[s]
	#EffectsPlayer.stream = stream
	#EffectsPlayer.play()

func _getPlayerFromCaller(caller : Node):
	if caller.has_node("AudioStreamPlayer"):
		return caller.get_node("AudioStreamPlayer")
	else:
		var player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		player.name = "AudioStreamPlayer"
		player.bus = "Effects"
		player.max_distance = MAX_DISTANCE
		caller.add_child(player)
		return player
