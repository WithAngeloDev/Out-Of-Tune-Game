extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var sweep_speed := 900.0
@export var jump_speed := 1600.0
@export var summon_top_prep_time := 0.4
@export var summon_bottom_prep_time := 0.5

@export var left_wall: Marker2D
@export var right_wall: Marker2D

var last_sweep_dir := -1  # -1 = left→right, 1 = right→left
var can_act := true

func _ready() -> void:
	BeatManager.connect("beat_window", on_beat)

func _physics_process(delta):
	
	#print(global_position)

	sprite_2d.flip_h = false if velocity.x < 0 else true

	move_and_slide()

# Called by global beat manager
func on_beat():
	if can_act:
		do_random_attack()

func do_random_attack():
	var attacks = [
		attack_sweep,
		#attack_jump_lunge,
		#attack_summon_top,
		#attack_summon_bottom
	]
	attacks.pick_random().call()

# Called by music time system
func do_timed_attack(name: String):
	match name:
		"sweep": attack_sweep()
		#"jump": attack_jump_lunge()
		#"top": attack_summon_top()
		#"bottom": attack_summon_bottom()

func attack_sweep() -> void:
	
	if not can_act:
		return
	can_act = false

	# alternate direction every attack
	last_sweep_dir *= -1
	var dir = last_sweep_dir  # -1 = left → right sweep, 1 = right → left sweep

	var left_wall_x : float = left_wall.global_position.x
	var right_wall_x : float = right_wall.global_position.x

	# find the target x based on direction
	var target_x := right_wall_x if dir == 1 else left_wall_x
	
	global_position.x  = left_wall_x if target_x == right_wall_x else right_wall_x

	# windup
	await get_tree().create_timer(0.15).timeout

	# SET VELOCITY based on direction
	velocity.x = dir * sweep_speed

	# MOVE until boss reaches the wall
	while true:

		if dir == 1 and global_position.x >= target_x:
			break
		if dir == -1 and global_position.x <= target_x:
			break

		if get_tree():
			await get_tree().process_frame

	# STOP
	velocity.x = 0

	# tiny recovery
	await get_tree().create_timer(0.2).timeout
	can_act = true
