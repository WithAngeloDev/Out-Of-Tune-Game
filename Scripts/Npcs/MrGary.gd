extends AnimatedSprite2D

@onready var player_detect: Area2D = $PlayerDetect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_detect.connect("body_entered", player_entered)
	player_detect.connect("body_exited", player_exited)

func player_entered(body):
	if body.is_in_group("player"):
		animation_player.play("Entered")
		animated_sprite_2d.play("default")

func player_exited(body):
	if body.is_in_group("player"):
		animation_player.play_backwards("Entered")
		animated_sprite_2d.play_backwards("default")
