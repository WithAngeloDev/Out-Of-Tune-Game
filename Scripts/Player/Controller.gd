extends CharacterBody2D

@export var notes : Array[AudioStream]
@export var notes_dorian : Array[AudioStream]

const SPEED = 600.0
const SPRINT_MAX = 1200.0     # max sprint speed
const SPRINT_ACCEL = 800.0  # how fast u build sprint speed
const STOP_DECEL = 5000.0    # how fast u lose sprint speed when not moving
const JUMP_VELOCITY = -900.0
const WALL_SLIDE_SPEED = 80.0
const GRAVITY = 1200.0

var current_speed = SPEED
var can_double_jump_unlocked := false 
var can_double_jump := false
var can_move := true
var is_sprinting := false
var can_attack := false
var queued_sound := false
var stop_moving_dialogue := true
var can_gravity := true
var can_heal := true

var coyote_time = 0.1
var coyote_timer = 0.0

var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0

var note_index = 0
var beats_since_attack = 0

var old_pos: Vector2

@onready var sprite = $Sprite2D
@onready var violin_sprite: AnimatedSprite2D = $ViolinSprite
@onready var mat = sprite.material
@onready var note_to_play: AudioStreamPlayer = $NoteToPlay
@onready var long_particle: AnimatedSprite2D = $LongParticle
@onready var heal_progress: ProgressBar = $CanvasLayer/Control/HealProgressBar
@export var dash_speed := 1500.0
@export var dash_time := 0.15
@onready var dash_anim: AnimationPlayer = $CanvasLayer/UnlockedDash2/DashAnim
@onready var d_anim: AnimationPlayer = $CanvasLayer/UnlockedDash/DoubleJumpAnim
@onready var hurt_box: Hurtbox = $HurtBox

var is_dashing := false
@export var dash_cooldown := 0.6
var can_dash := true

@export var max_health := 3

@onready var hearts_container := $CanvasLayer/Control/Hearts   # HBoxContainer with TextureRects

var inside_tree:= false

func _process(delta: float) -> void:
	if is_on_floor():
		old_pos = global_position 

func _ready():
	#current_health = max_health
	_update_hearts()
	BeatManager.beat_window.connect(_on_beat_window)
	BeatManager.beat.connect(_on_perfect_beat)

var hitstop_active := false
var stored_timescale := 1.0

func do_dash():
	if is_dashing or not can_dash && !Global.has_dash:
		return

	$CollisionShape2D.get_parent().collision_mask = 1

	is_dashing = true
	can_dash = false
	can_move = false
	can_gravity = false

	var dir = -1 if sprite.flip_h else 1
	velocity = Vector2(dir * dash_speed, 0)

	await get_tree().create_timer(dash_time).timeout

	if !inside_tree:
		
		is_dashing = false
		can_move = true
		can_gravity = true
		
		collision_mask = 0  # reset
		set_collision_mask_value(1, true)   # layer 1
		set_collision_mask_value(13, true)  # layer 13

		# start cooldown
		await get_tree().create_timer(dash_cooldown).timeout
		can_dash = true
		

func take_damage(amount, knockback_dir := Vector2.ZERO, damager = null):
	#if Global.current_health <= 0:
	#	return

	
	Global.current_health -= amount
	
	if Global.current_health <= 0:
		get_tree().change_scene_to_file(Global.saved_level)
		Global.current_health = max_health
		print("LEVEEEL: ", Global.saved_level)
		return
	
	# ---------------------------
	# Turn OFF hurtbox for i-frames
	# ---------------------------
	var old_layer = $HurtBox.collision_layer
	$HurtBox.collision_layer = 0   # becomes untouchable

	if Global.current_health < 0:
		Global.current_health = 0

	_update_hearts()

	# ---------------------------
	# Pop both player + enemy to front
	# ---------------------------
	var old_player_z = z_index
	var old_enemy_z = 0
	if damager != null:
		old_enemy_z = damager.owner.z_index
		damager.owner.z_index = 300

	sprite.z_index = 300

	$Flash/AnimationPlayer.play("flash")
	$Flash2/AnimationPlayer.play("flash")
	
	# ---------------------------
	# Apply knockback immediately
	# ---------------------------
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * 900

	# hitstop (non-stacking)
	if not hitstop_active:
		hitstop_active = true
		stored_timescale = Engine.time_scale
		Engine.time_scale = 0.1
		can_move = false

		spawn_particle(preload("uid://jq10wm7hhrd"), Vector2.ZERO)


		if get_tree():
			await get_tree().create_timer(0.07, true).timeout

		Engine.time_scale = stored_timescale
		can_move = true
		hitstop_active = false

	# Reset z-index
	sprite.z_index = old_player_z
	if damager != null:
		damager.owner.z_index = old_enemy_z

	# ---------------------------
	# Restore hurtbox after 1.5s
	
	$FlashAnim.play("flash")
	
	await get_tree().create_timer(1).timeout
	$HurtBox.collision_layer = old_layer

func _update_hearts():
	# assumes hearts_container children are in order: [heart1, heart2, heart3...]
	for i in range(hearts_container.get_child_count()):
		var heart = hearts_container.get_child(i)
		heart.visible = i < Global.current_health

func spawn_particle(scene: PackedScene, pos: Vector2, rot = 0):
	var particle = scene.instantiate()
	
	particle.global_position = pos
	particle.rotation = rot
	
	$CanvasLayer/Marker2D.add_child(particle)
	
	if particle is AnimatedSprite2D:
		await particle.animation_finished
		particle.queue_free()

func _physics_process(delta):
	
	can_double_jump_unlocked = Global.has_double_jump
	
	if Dialogic.current_timeline != null:
		if stop_moving_dialogue:
			velocity.x = 0
		can_move = false
	
	handle_gravity(delta)
	handle_input(delta)
	
	update_animation()
	
	if inside_tree:
		is_dashing = true
		can_dash = false
		can_move = false
		can_gravity = false

		$CollisionShape2D.get_parent().collision_mask = 1

		var dir = -1 if sprite.flip_h else 1
		velocity = Vector2(dir * dash_speed, 0)
	
	if is_dashing:
		move_and_slide()
		return
	
	$DustParticle.emitting = velocity.x != 0 && velocity.y == 0
	
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

	heal_progress.value = Global.perfect_streak
	heal_progress.material.set_shader_parameter("percentage", float(Global.perfect_streak/5))
	#print(float(Global.perfect_streak/5))
	
	if Global.perfect_streak < 5:
		heal_progress.material.set_shader_parameter("water_colour", Color(0.758, 0.758, 0.758, 1.0))
		heal_progress.modulate = Color(0.758, 0.758, 0.758, 1.0)
	else:
		heal_progress.material.set_shader_parameter("water_colour", Color(1.0, 1.0, 1.0, 1.0))
		heal_progress.modulate = Color(1.0, 1.0, 1.0, 1.0)

	handle_attack()
	handle_jump()
	move_and_slide()

func handle_gravity(delta):
	if !can_gravity: return
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_input(delta):
	
	if Input.is_action_just_pressed("debug"):
		get_tree().change_scene_to_file(Global.saved_level)
		Engine.time_scale = 1
		Global.current_health = max_health
	
	if Input.is_action_just_pressed("Heal") && Global.perfect_streak >=5:
		heal()
	
	if Input.is_action_just_pressed("dash") && Global.has_dash:
		do_dash()
		return
	
	violin_sprite.flip_h = sprite.flip_h 
	
	if !can_move: return
	
	var dir = Input.get_axis("left", "right")
	

	# flip
	if dir != 0:
		sprite.flip_h = dir < 0

	# sprint input (boolean)
	#is_sprinting = Input.is_action_pressed("sprint") and dir != 0 and is_on_floor()

	if is_sprinting:
		# accelerate up to sprint max
		current_speed = min(current_speed + SPRINT_ACCEL * delta, SPRINT_MAX)
	else:
		# lose speed back down to normal
		current_speed = max(current_speed - STOP_DECEL * delta, SPEED)

	# movement
	velocity.x = dir * current_speed

func update_animation():
	if !is_dashing:
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
	else:
		sprite.play("dash")

func heal():
	if !can_heal: return
	
	Global.perfect_streak = 0
	
	velocity = Vector2.ZERO
	
	can_heal = false
	can_move = false
	can_gravity = false
	
	sprite.z_index = 300

	$Flash/AnimationPlayer.play("flash")
	$Flash2/AnimationPlayer.play("flash")
	
	Engine.time_scale = 0.6
	
	await get_tree().create_timer(0.6, true, false, true).timeout
	
	Engine.time_scale = 1
	
	sprite.z_index = 1
	
	if Global.current_health < max_health:
		Global.current_health += 1
		_update_hearts()
	
	can_heal = true
	can_move = true
	can_gravity = true

func handle_jump():
	
	if !can_move: return
	
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
		velocity.y = jump_force  
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
	
	if !can_move: return
	
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
			
			get_tree().get_first_node_in_group("Camera").add_shake(0.8)
			get_tree().get_first_node_in_group("Camera").zoom_punch(0.009)
			
			Global.miss_amount += 1
			
			if Global.miss_amount >= 2:
				Global.miss_amount = 0
			
			if Global.perfect_streak > 0:
				Global.perfect_streak -= 1
			
			#note_index = 0
			print("MISS! Attack was off-beat")

var reverse_violin := false

func _on_perfect_beat():
	if queued_attack and not missed_attack:
		queued_attack = false
		
		if get_tree().get_first_node_in_group("Camera"):
			get_tree().get_first_node_in_group("Camera").add_shake(0.8)
			get_tree().get_first_node_in_group("Camera").zoom_punch(0.005)
		
		# alternate forward/backward each time
		if reverse_violin:
			violin_sprite.play_backwards("Violin")
		else:
			violin_sprite.play("Violin")
		
		BeatManager.effect.play("default")
		
		long_particle.play("default")
		long_particle.rotation = randf_range(-360, 360)

		reverse_violin = !reverse_violin


		if Global.perfect_streak < 5:
			Global.perfect_streak += 1

		# spawn slash exactly on beat
		var slash = preload("uid://bhs8qinhy7pnf").instantiate()
		slash.global_position = $SlashSpawn.global_position
		slash.direction = (get_global_mouse_position() - global_position).normalized()
		if get_tree():
			get_tree().current_scene.add_child(slash)
		slash.hitbox.hurt_box = $HurtBox

		if BeatManager.music_player.stream != preload("uid://c7xk8l522n424"):
			# play note
			note_to_play.stream = notes[note_index]
			note_to_play.play()
			note_index += 1
			if note_index >= notes.size():
				note_index = 0
		else:
			# play note
			note_to_play.stream = notes_dorian[note_index]
			note_to_play.play()
			note_index += 1
			if note_index >= notes_dorian.size():
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


func _on_dash_tree_area_entered(area: Area2D) -> void:
	inside_tree = true
	print("HOYYAAA")

func _on_dash_tree_area_exited(area: Area2D) -> void:
	inside_tree = false
	is_dashing = false
	can_move = true
	can_gravity = true
	can_dash = true
	collision_mask = 0  # reset
	set_collision_mask_value(1, true)   # layer 1
	set_collision_mask_value(13, true)  # layer 13
