extends CharacterBody2D

@export var notes : Array[AudioStream]

const SPEED = 600.0
const SPRINT_MAX = 1200.0     # max sprint speed
const SPRINT_ACCEL = 800.0  # how fast u build sprint speed
const STOP_DECEL = 5000.0    # how fast u lose sprint speed when not moving
const JUMP_VELOCITY = -800.0
const WALL_SLIDE_SPEED = 80.0
const GRAVITY = 1200.0

var current_speed = SPEED
var can_double_jump_unlocked := true 
var can_double_jump := false
var can_move := true
var is_sprinting := false
var can_attack := false
var queued_sound := false

var coyote_time = 0.1
var coyote_timer = 0.0

var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

var note_index = 0
var beats_since_attack = 0

@onready var sprite = $Sprite2D
@onready var violin_sprite: AnimatedSprite2D = $ViolinSprite
@onready var mat = sprite.material
@onready var note_to_play: AudioStreamPlayer = $NoteToPlay
@onready var long_particle: AnimatedSprite2D = $LongParticle

func _ready() -> void:
	BeatManager.beat_window.connect(_on_beat_window)
	BeatManager.beat.connect(_on_perfect_beat)

func _physics_process(delta):
	handle_gravity(delta)
	handle_input(delta)
	
	# update coyote timer
	if is_on_floor():
		can_double_jump = false
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# update jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	handle_attack()
	handle_jump()
	move_and_slide()
	update_animation()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_input(delta):
	
	violin_sprite.flip_h = sprite.flip_h 
	
	if !can_move: return
	
	var dir = Input.get_axis("left", "right")
	

	# flip
	if dir != 0:
		sprite.flip_h = dir < 0

	# sprint input (boolean)
	is_sprinting = Input.is_action_pressed("sprint") and dir != 0 and is_on_floor()

	if is_sprinting:
		# accelerate up to sprint max
		current_speed = min(current_speed + SPRINT_ACCEL * delta, SPRINT_MAX)
	else:
		# lose speed back down to normal
		current_speed = max(current_speed - STOP_DECEL * delta, SPEED)

	# movement
	velocity.x = dir * current_speed

func update_animation():
	if not is_on_floor():
		sprite.play("Jump")
	elif velocity.x == 0:
		sprite.play("Idle")
	else:
		# use the sprint boolean for sprint animation
		if is_sprinting:
			sprite.play("Sprint")   # make sure you have this animation
		else:
			sprite.play("Walk")

func handle_jump():
	# check sprint jump boost
	var jump_force = JUMP_VELOCITY
	if is_sprinting:
		jump_force *= 1.2

	# actual jump trigger using timers
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_force
		jump_buffer_timer = 0
		coyote_timer = 0

	# DOUBLE JUMP
	if can_double_jump_unlocked and jump_buffer_timer > 0 and not is_on_floor() and not can_double_jump:
		velocity.y = jump_force * 0.85  
		can_double_jump = true
		jump_buffer_timer = 0
		return

	# wall jump
	#elif jump_buffer_timer > 0 and is_on_wall():
		#velocity.y = jump_force
		#velocity.x = -get_wall_normal().x * SPEED
		#jump_buffer_timer = 0

	# short hop
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.4

var missed_attack = false  # new flag

var queued_attack = false

func handle_attack():
	if Input.is_action_just_pressed("attack"):
		if can_attack:
			# click inside beat window → queue attack
			queued_attack = true
			can_attack = false
			print("ATTACK QUEUED!")
		else:
			# click outside beat window → miss immediately
			missed_attack = true
			queued_attack = false
			#note_index = 0
			print("MISS! Attack was off-beat")

var reverse_violin := false

func _on_perfect_beat():
	if queued_attack and not missed_attack:
		queued_attack = false
		
		# alternate forward/backward each time
		if reverse_violin:
			violin_sprite.play_backwards("Violin")
		else:
			violin_sprite.play("Violin")
		
		long_particle.play("default")
		long_particle.rotation = randf_range(-360, 360)

		reverse_violin = !reverse_violin


		# spawn slash exactly on beat
		var slash = preload("uid://bhs8qinhy7pnf").instantiate()
		slash.global_position = $SlashSpawn.global_position
		slash.direction = (get_global_mouse_position() - global_position).normalized()
		if get_tree():
			get_tree().current_scene.add_child(slash)
		slash.hitbox.hurt_box = $HurtBox

		# play note
		note_to_play.stream = notes[note_index]
		note_to_play.play()
		note_index += 1
		if note_index >= notes.size():
			note_index = 0

		# shader effect
		mat.set_shader_parameter("clip_y", 0.54)
		violin_sprite.show()
		beats_since_attack = 0
	else:
		beats_since_attack += 1
		if beats_since_attack >= 2:
			mat.set_shader_parameter("clip_y", 0.0)
			violin_sprite.hide()
			beats_since_attack = 0

	missed_attack = false

func do_pogo():
	# only pogo if falling
	if velocity.y > 0: 
		velocity.y = JUMP_VELOCITY * 0.6

	can_double_jump = true

	# juicy freeze
	#Engine.time_scale = 0.6
	#await get_tree().create_timer(0.08).timeout
	#Engine.time_scale = 1.0

func _on_beat_window():
	can_attack = true
	if get_tree():
		await get_tree().process_frame
	can_attack = false
