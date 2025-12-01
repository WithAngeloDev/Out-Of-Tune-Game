extends Node2D

func _ready():
	
	
	var player = get_tree().get_first_node_in_group("player")
	if !player: return
	
	var light = player.get_node("light")
	var light_energy = player.get_node("light").energy
	var tween = create_tween()

	light.energy = 0
	tween.tween_property(light, "energy", light_energy, 0.4) # duration 0.4s
	if Global.next_door_id == "":
		return

	var spawn_door = find_door(Global.next_door_id)
	
	if spawn_door:
		if player:
			# place player at the door's exact spot
			player.global_position = spawn_door.global_position

			# apply hollow-knight style push
			#if "velocity" in player:
			player.can_move = false
			player.velocity.x = spawn_door.exit_push.x
			if spawn_door.exit_push.y != 0:
				player.velocity.y = spawn_door.exit_push.y
			
			var dir = sign(player.velocity.x)

			player.sprite.flip_h = dir < 0
			
			await get_tree().create_timer(0.6).timeout
			player.can_move = true
			player.velocity.x = 0

	Global.next_door_id = ""
	
	if name == "Level5" && Global.has_dash:
		$Leafthing2/AnimationPlayer.play("Leaf")
	
	if name == "Level3" && Global.has_double_jump:
		if !Global.blocked_path1:
			get_tree().get_first_node_in_group("player").can_move = false
		$Door3.monitoring = false
		$Door3/Leafthing/AnimationPlayer.play("Beg")
		await get_tree().create_timer(1.4).timeout
		$Door3/StaticBody2D/CollisionShape2D.disabled = false
		if !Global.blocked_path1:
			Dialogic.start(preload("uid://cdlp6naomyay4"))
			await Dialogic.timeline_ended
			get_tree().get_first_node_in_group("player").can_move = true
			Global.blocked_path1 = true

func find_door(id: String):
	for door in get_tree().get_nodes_in_group("doors"):
		if door.door_id == id:
			return door
	return null

func _on_camera_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && !Global.defeated_boss1:
		$Boss1.can_act = true
		$Enviroment/Sprite2D/Door.play("door")
		BeatManager.play_song(preload("uid://cewi8fghfds3c"))
		$CanvasLayer/ColorRect/Shockwave.play("shock")
		$Boss1/Start.play()
		$Camera/CameraArea2.queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void: 
	if body.is_in_group("player"):
		$Leafthing2/AnimationPlayer.play("Leaf")

func _on_door_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		BeatManager.play_song(preload("res://Audio/Music/Ost2.mp3"))
