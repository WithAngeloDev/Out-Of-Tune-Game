extends CharacterBody2D

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var dust_particle: GPUParticles2D = $"../DustParticle"
@onready var anim: AnimationPlayer = $Anim

@export var sweep_speed := 900.0
@export var jump_speed := 1600.0
@export var summon_top_prep_time := 0.4
@export var summon_bottom_prep_time := 0.5

@export var left_wall: Marker2D
@export var right_wall: Marker2D

@export var spike_markers: Array[Marker2D]
@export var spike_scene: PackedScene   # the spike you will spawn
@export var big_spike_scene: PackedScene   # the spike you will spawn

var last_sweep_dir := -1  # -1 = left→right, 1 = right→left
var can_act := false
var is_top := false
var is_in_phase2 := false

var last_attack := ""

var health: int = 35

func _ready() -> void:
	BeatManager.connect("beat_window", on_beat)
	
	if Global.defeated_boss1:
		queue_free()

func _physics_process(delta):
	
	#print(global_position)

	if !is_top:
		if velocity.x < 0:
			sprite_2d.flip_h = false 
		elif velocity.x > 0:
			sprite_2d.flip_h = true 
	else:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			if player.global_position.x < global_position.x:
				sprite_2d.flip_h = false
			else:
				sprite_2d.flip_h = true

	move_and_slide()

# Called by global beat manager
func on_beat():
	if can_act:
		do_random_attack()

var attack_order = [
	"attack_sweep",
	"attack_sweep",
	"attack_summon_bottom",
	"attack_summon_top",
	"attack_sweep",
	"attack_summon_top",
	"attack_sweep",
	"attack_summon_bottom",
]

var attack_index = 0

func do_random_attack():
	var chosen = attack_order[attack_index]
	attack_index += 1

	# loop back when reaching the end
	if attack_index >= attack_order.size():
		attack_index = 0

	last_attack = chosen
	call(chosen)

func attack_sweep() -> void:
	if not can_act:
		return
	can_act = false

	$SweepAttack.play()

	print("SWEEEEEEEP")
	
	sprite_2d.play("Walk")

	# alternate direction every attack
	last_sweep_dir *= -1
	var dir = last_sweep_dir  # -1 = left → right sweep, 1 = right → left sweep

	var left_wall_x : float = left_wall.global_position.x
	var right_wall_x : float = right_wall.global_position.x

	# find the target x based on direction
	var target_x := right_wall_x if dir == 1 else left_wall_x
	
	#global_position.x  = left_wall_x if target_x == right_wall_x else right_wall_x

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

func attack_summon_bottom() -> void:
	if not can_act:
		return
	can_act = false

	await BeatManager.beat
	await BeatManager.beat

	print("BOSS: bottom spikes")

	var used_positions := 0
	var total := spike_markers.size()

	# cycle in order
	for i in range(total):

		var pos := spike_markers[i].global_position
		
		dust_particle.global_position = pos
		dust_particle.emitting = true
		await BeatManager.beat

		# spawn spike
		var spike = spike_scene.instantiate()
		spike.global_position = pos
		get_tree().current_scene.add_child(spike)

		used_positions += 1

		# wait next beat
		#await BeatManager.beat
		dust_particle.emitting = false

	# done
	await get_tree().create_timer(0.2).timeout
	can_act = true

func attack_summon_top() -> void:
	if not can_act:
		return
	can_act = false
	#sprite_2d.flip_h = false
	
	var player = get_tree().get_first_node_in_group("player")

	is_top = true
	
	$Attacks.play()
	
	dust_particle.emitting = true
	dust_particle.global_position = global_position
	
	await BeatManager.beat
	
	sprite_2d.play("Walk")
	anim.play("Summon")
	
	await BeatManager.beat
	await BeatManager.beat
	
	dust_particle.emitting = false
	
	var total := 5


	# cycle in order
	for i in range(total):
		
		sprite_2d.play("Summon")
		
		var pos = player.global_position.x
		if !$"../Indecator": return
		$"../Indecator/AnimationPlayer".play("Indecate")
		$"../Indecator".global_position.x = pos
		
		#$Attacks2.play()
		
		await BeatManager.beat
		await BeatManager.beat
		
		# spawn spike
		var spike = big_spike_scene.instantiate()
		spike.global_position.x = pos
		spike.global_position.y = $"../Spikepos1".global_position.y
		if get_tree():
			get_tree().current_scene.add_child(spike)
	
	if $"../Indecator/AnimationPlayer":
		$"../Indecator/AnimationPlayer".play_backwards("Indecate")
	
	#anim.play_backwards("Summon")
	#await anim.animation_finished
	
	await get_tree().create_timer(0.2).timeout
	can_act = true
	is_top = false

func _on_hurt_box_on_damaged(amount, dir, damager) -> void:
	health -= amount
	
	print(health)
	
	if health <= 0 && !is_in_phase2:
		
		print("PHASE 2")
		
		health = 20
		
		if $"../Indecator/AnimationPlayer":
			$"../Indecator/AnimationPlayer".play_backwards("Indecate")
		
		BeatManager.stop_song()
		velocity = Vector2.ZERO
		
		Engine.time_scale = 0.2
		
		can_act = false
		is_top = false
		
		await get_tree().create_timer(0.8, true, false, true).timeout
		
		Engine.time_scale = 1
		if $"../Indecator/AnimationPlayer":
			$"../Indecator/AnimationPlayer".play_backwards("Indecate")
		
		await get_tree().create_timer(2, true, false, true).timeout
		
		can_act = true
		
		await get_tree().process_frame
		is_in_phase2 = true
		
		health = 20
		sweep_speed = 1200
		Engine.time_scale = 1
		
		attack_sweep()
		
		await get_tree().create_timer(0.8, true, false, true).timeout
		
		BeatManager.play_song(preload("res://Audio/Music/Ost3.mp3"))
	elif is_in_phase2 && health <= 0:
		
		
		health = 0
		
		Global.defeated_boss1 = true
		if $"../Indecator":
			$"../Indecator".queue_free()
		
		$"../DustParticle".emitting = false
		
		BeatManager.stop_song()
		velocity = Vector2.ZERO
		
		Engine.time_scale = 0.2
		
		is_in_phase2 = false
		
		can_act = false
		is_top = false
		
		await get_tree().create_timer(0.8, true, false, true).timeout
		
		$"../Enviroment/Sprite2D/Door".play_backwards("door")
		
		Global.has_dash = true
		
		Engine.time_scale = 1
		
		queue_free()
		
		get_tree().get_first_node_in_group("player").dash_anim.play("d")
