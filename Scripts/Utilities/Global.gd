extends Node

var next_door_id: String = ""
var just_teleported := false

func _ready() -> void:
	var song = preload("res://Audio/Music/Ost3.mp3")
	
	if BeatManager.music_player.stream != song:
		BeatManager.play_song(song)
