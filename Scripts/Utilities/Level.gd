extends Node2D

func _ready():
	if Global.next_door_id == "":
		return

	var spawn_door = find_door(Global.next_door_id)
	if spawn_door:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# place player at the door's exact spot
			player.global_position = spawn_door.global_position

			# apply hollow-knight style push
			#if "velocity" in player:
			player.can_move = false
			player.velocity.x = spawn_door.exit_push.x
			
			var dir = sign(player.velocity.x)

			player.sprite.flip_h = dir < 0
			
			var light = player.get_node("light")
			var light_energy = player.get_node("light").energy
			var tween = create_tween()

			light.energy = 0
			tween.tween_property(light, "energy", light_energy, 0.4) # duration 0.4s
			
			await get_tree().create_timer(0.6).timeout
			player.can_move = true
			player.velocity.x = 0

	Global.next_door_id = ""

func find_door(id: String):
	for door in get_tree().get_nodes_in_group("doors"):
		if door.door_id == id:
			return door
	return null
