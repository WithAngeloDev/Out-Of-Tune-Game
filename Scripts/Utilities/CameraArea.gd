extends Area2D

@export var original_camera: PhantomCamera2D
@export var new_camera: PhantomCamera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", player_entered)
	connect("body_exited", player_exited)

func player_entered(body):
	if body.is_in_group("player"):
		print("YHH CHANGE")
		original_camera.priority = 0
		new_camera.priority = 20

func player_exited(body):
	if body.is_in_group("player"):
		original_camera.priority = 10
		new_camera.priority = 0
