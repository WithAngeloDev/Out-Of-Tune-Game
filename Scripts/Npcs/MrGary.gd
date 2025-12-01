extends AnimatedSprite2D

@export var dialogue: DialogicTimeline

@onready var player_detect: Area2D = $PlayerDetect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var player_here: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_detect.connect("body_entered", player_entered)
	player_detect.connect("body_exited", player_exited)
	
	Dialogic.connect("signal_event", signals)

func player_entered(body):
	if Dialogic.current_timeline != null: return 
	if body.is_in_group("player"):
		animation_player.play("Entered")
		animated_sprite_2d.play("default")
		
		player_here = true

func player_exited(body):
	if body.is_in_group("player"):
		animation_player.play_backwards("Entered")
		animated_sprite_2d.play_backwards("default")
		
		player_here = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact") && Dialogic.current_timeline == null && player_here:
		Dialogic.start(dialogue)
		
		get_tree().get_first_node_in_group("player").velocity.x = 0
		
		animation_player.play_backwards("Entered")
		
		BeatManager.music_player.volume_db -= 10
		
		await Dialogic.timeline_ended 
		
		BeatManager.music_player.volume_db += 10
		
		#$PlayerDetect.queue_free()
		
		get_tree().get_first_node_in_group("player").can_move = true

func signals(args):
	if args == "player_is_leaving":
		get_tree().get_first_node_in_group("player").stop_moving_dialogue = false
		get_tree().get_first_node_in_group("player").velocity.x = 400
		get_tree().get_first_node_in_group("player").sprite.flip_h = false
	if args == "player_stop":
		get_tree().get_first_node_in_group("player").stop_moving_dialogue = true
		get_tree().get_first_node_in_group("player").velocity.x = 0
		await get_tree().create_timer(0.5).timeout
		get_tree().get_first_node_in_group("player").sprite.flip_h = true
