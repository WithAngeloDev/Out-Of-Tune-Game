extends Control

func _on_play_button_pressed() -> void:
	$ColorRect2/AnimationPlayer.play("Fade")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file(Global.saved_level)
	Global._ready()
	
	var song = preload("res://Audio/Music/Ost2.mp3")
	if BeatManager.music_player.stream != song:
		BeatManager.play_song(song)
