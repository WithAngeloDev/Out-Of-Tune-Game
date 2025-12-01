extends Area2D

@export var animation_player: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", ar_en)
	connect("body_exited", ar_ex)

func ar_en(body):
	if body.is_in_group("player"):
		animation_player.play("t")

func ar_ex(body):
	if body.is_in_group("player"):
		animation_player.play_backwards("t")
