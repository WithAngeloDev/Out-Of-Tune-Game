extends Node2D

func spawn_particle(scene: PackedScene, pos: Vector2, rot = 0):
	var particle = scene.instantiate()
	
	particle.global_position = pos
	particle.rotation = rot
	
	get_tree().current_scene.add_child(particle)
	
	if particle is AnimatedSprite2D:
		await particle.animation_finished
		particle.queue_free()
