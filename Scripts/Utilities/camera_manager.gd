extends Node2D

@export var look_ahead_amount := Vector2(200, 0)
@export var smooth_speed := 5.0

@export var zoom_punch_decay := 0.08   # how fast zoom goes back to normal
var zoom_punch_strength := 0.0


@export var shake_decay := 2.0   # how fast shake fades out
var shake_strength := 0.0        # current shake level

@onready var camera: PhantomCamera2D = $PhantomCamera2D
@onready var org_camera: Camera2D = $Camera2D

var target_offset := Vector2.ZERO

func add_shake(amount: float) -> void:
	shake_strength += amount
	# never go negative just in case
	if shake_strength < 0.0:
		shake_strength = 0.0

func _process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# ------------------------
	# LOOK AHEAD LOGIC
	# ------------------------
	var dir = player.velocity

	target_offset = Vector2(
		clamp(dir.x, -1, 1) * look_ahead_amount.x,
		clamp(dir.y, -1, 1) * look_ahead_amount.y
	)

	# smooth follow
	camera.follow_offset = camera.follow_offset.lerp(target_offset, smooth_speed * delta)

	# ------------------------
	# CAMERA SHAKE
	# ------------------------
	if shake_strength > 0.0:
		var shake = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_strength

		org_camera.offset = shake

		# decay
		shake_strength -= shake_decay * delta
		if shake_strength < 0.0:
			shake_strength = 0.0
	else:
		# no shake, reset
		org_camera.offset = Vector2.ZERO
	
		# ------------------------
	# ZOOM PUNCH
	# ------------------------
	if zoom_punch_strength > 0.0:
		# base zoom is 1.0, so we reduce it temporarily
		org_camera.zoom = camera.zoom * (1.0 - zoom_punch_strength)

		zoom_punch_strength -= zoom_punch_decay * delta
		if zoom_punch_strength < 0.0:
			zoom_punch_strength = 0.0
	else:
		org_camera.zoom = camera.zoom

func zoom_punch(amount: float) -> void:
	zoom_punch_strength += amount
	if zoom_punch_strength < 0.0:
		zoom_punch_strength = 0.0
