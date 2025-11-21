extends Node

var next_door_id: String = ""
var just_teleported := false

func _ready() -> void:
	BeatManager.play_song(preload("res://Audio/Music/Ost2.mp3"))
