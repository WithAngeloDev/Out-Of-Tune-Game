extends Area2D

@export var door_id: String
@export var exit_push := Vector2(500, 0)  # hollow knight kind of push yk
@export_file("*.tscn") var target_scene: String

func _ready():
	
	add_to_group("doors")
	await get_tree().create_timer(0.4).timeout
	Global.just_teleported = false
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	if Global.just_teleported:
		return  # ignore if coming from a teleport

	Global.just_teleported = true
	Global.next_door_id = door_id

	var player = get_tree().get_first_node_in_group("player")
	
	player.can_move = false
	player.velocity.x = -exit_push.x
	var light = player.get_node("light")
	var tween = create_tween()

	tween.tween_property(light, "energy", 0.0, 0.4) # duration 0.4s

	
	await get_tree().create_timer(0.4).timeout

	get_tree().change_scene_to_file(target_scene)
