extends Node

var next_door_id: String = ""
var just_teleported := false
var defeated_boss1 := false
var has_double_jump := false
var has_dash := false
var blocked_path1 := false

var current_health: int = 3

var saved_level = "res://Scenes/Start/Level0.tscn"

var perfect_streak := 0.0
var miss_amount := 0

func _ready() -> void:
	
	#BeatManager.play_song(preload("uid://c7xk8l522n424"))
	
	if get_tree().get_first_node_in_group("player"):
		current_health = get_tree().get_first_node_in_group("player").max_health
