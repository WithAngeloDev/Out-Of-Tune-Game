extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", body_entered)

func body_entered(body):
	if body.is_in_group("player"):
		body.hurt_box.apply_damage(1, Vector2.ZERO)
		body.global_position = body.old_pos
