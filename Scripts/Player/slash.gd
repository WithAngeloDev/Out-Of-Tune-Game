extends Node2D

var direction = Vector2.ZERO
var speed = 1800.0
var lifetime = 0.12

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	sprite_2d.look_at(get_global_mouse_position())
	hitbox.connect("area_entered", self._on_hit)

func _process(delta):
	position += speed * direction * delta

func _on_hit(area):
	if not area.is_in_group("hurtbox"):
		return

	#if area.has_method("apply_damage"):
		#area.apply_damage(1)

	# get player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# only pogo if player is ABOVE enemy + falling down
	if player.global_position.y < area.global_position.y and player.velocity.y > 0:
		player.do_pogo()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	queue_free()
