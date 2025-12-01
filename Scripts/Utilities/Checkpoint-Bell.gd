extends Area2D

@onready var bell_sfx: AudioStreamPlayer = $BellSFX
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var shockwave: AnimationPlayer = $CanvasLayer/ColorRect/Shockwave

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("area_entered", player_entered)

func player_entered(body):
	if body.is_in_group("Slash"):
		bell_sfx.play()
		animation_player.play("bell")
		shockwave.play("shock")
		Global.saved_level = get_tree().current_scene.scene_file_path
		Global.current_health = 3
		get_tree().get_first_node_in_group("player")._update_hearts()
