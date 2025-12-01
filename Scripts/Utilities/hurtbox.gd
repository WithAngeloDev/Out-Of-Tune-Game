extends Area2D
class_name Hurtbox

@export var health := 5
@export var sprite : Node2D    # sprite that has flash shader material
@export var flash_time := 0.1    # how long the flash lasts

var flashing := false

signal on_damaged(amount, knockback, damager)

func _ready() -> void:
	add_to_group("hurtbox")

func apply_damage(amount, dir, damager = null):
	health -= amount
	#print("enemy hp:", health)

	# rotation is the angle of the hit direction
	var rot = dir.angle()

	ParticleEffects.spawn_particle(preload("uid://c81myf4bsv7ed"), global_position, rot)
	ParticleEffects.spawn_particle(preload("uid://jq10wm7hhrd"), global_position, rot)

	emit_signal("on_damaged", amount, dir, damager)

	if sprite:
		flash()

	if health <= 0:
		die()

func flash():
	if flashing:
		return

	flashing = true
	var mat = sprite.material
	mat.set_shader_parameter("flash_amount", 1.0)

	await get_tree().create_timer(flash_time).timeout

	mat.set_shader_parameter("flash_amount", 0.0)
	
	flashing = false

func die():
	get_parent().queue_free()
	get_tree().get_first_node_in_group("Camera").add_shake(1)
	get_tree().get_first_node_in_group("Camera").zoom_punch(0.01)
