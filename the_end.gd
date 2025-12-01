extends Control

func _ready() -> void:
	BeatManager.stop_song()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
