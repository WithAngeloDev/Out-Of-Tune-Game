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
	Dialogic.connect("state_changed", state_changed)

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
		
		await Dialogic.timeline_ended
		
		#$PlayerDetect.queue_free()
		
		get_tree().get_first_node_in_group("player").can_double_jump_unlocked = true
		get_tree().get_first_node_in_group("player").can_move = true

func state_changed(args):
	play("default")

func signals(args):
	if args == "player_is_leaving":
		pass
