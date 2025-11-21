extends Node2D

@export var look_ahead_amount := Vector2(200, 0)   # max offset for X/Y
@export var smooth_speed := 5.0                    # how fast camera follows

@onready var camera: PhantomCamera2D = $PhantomCamera2D

var target_offset := Vector2.ZERO

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Determine direction based on velocity
	var dir = player.velocity
	# Optional: scale how much the camera looks ahead
	target_offset = Vector2(
		clamp(dir.x, -1, 1) * look_ahead_amount.x,
		clamp(dir.y, -1, 1) * look_ahead_amount.y
	)

	# Smoothly interpolate camera offset
	camera.follow_offset = camera.follow_offset.lerp(target_offset, smooth_speed * delta)
