extends CharacterBody2D

@export var dash_speed := 200
@export var dash_time := 0.25
@export var attack_range := 350
@export var distance_to_blind := 1100
@export var back_off_distance := 500

@export var accel := 900
@export var friction := 600

@onready var sprite = $Sprite
@onready var detect_area = $Rays/PlayerDetect
@onready var hitbox: Area2D = $Rays/Hitbox
@onready var rays: Node2D = $Rays

var player_ref = null
var attacking = false
var queued_attack := false

func _ready():
	detect_area.body_entered.connect(_on_player_detect)
	BeatManager.beat_window.connect(_on_beat_window)

func _physics_process(delta):

	if player_ref and global_position.distance_to(player_ref.global_position) >= distance_to_blind:
		player_ref = null

	if player_ref:
		var dir = sign(player_ref.global_position.x - global_position.x)
		sprite.scale.x = abs(sprite.scale.x) * -dir
		rays.scale.x = abs(rays.scale.x) * -dir

	if attacking:
		move_and_slide()
		return

	# sliding / idle movement
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	sprite.play("Idle")
	move_and_slide()

## -----------------------------
##   PLAYER DETECTION + ATTACK
## -----------------------------

func _on_player_detect(body):
	if body.is_in_group("player"):
		player_ref = body
		queued_attack = true   # allow first attack on next beat

func _on_beat_window():
	if player_ref == null:
		return

	if queued_attack and not attacking:
		queued_attack = false
		attack_cycle()

func attack_cycle() -> void:
	attacking = true
	await attack_and_backoff()
	attacking = false

	# allow attack again on next beat IF still near player
	if player_ref:
		queued_attack = true


func attack_and_backoff() -> void:
	# --------------------------------
	# DASH TOWARD PLAYER ON THE BEAT
	# --------------------------------
	if player_ref == null:
		return

	var dir_to_player = (player_ref.global_position - global_position).normalized()
	var dash_timer = dash_time
	hitbox.monitoring = false

	while dash_timer > 0 and player_ref:
		var target_vel = dir_to_player * dash_speed
		velocity = velocity.move_toward(target_vel, accel * get_process_delta_time())
		move_and_slide()
		dash_timer -= get_process_delta_time()
		await get_tree().process_frame

	# --------------------------------
	# ATTACK IF IN RANGE
	# --------------------------------
	if player_ref and global_position.distance_to(player_ref.global_position) <= attack_range:

		sprite.play("Attack")
		await get_tree().create_timer(0.3).timeout

		hitbox.monitoring = true
		await sprite.animation_finished
		hitbox.monitoring = false

		sprite.play("Idle")

		# BACK OFF
		var back_dir = (global_position - player_ref.global_position).normalized()
		var back_timer = 0.6

		while back_timer > 0:
			var target_back = back_dir * dash_speed
			velocity = velocity.move_toward(target_back, accel * get_process_delta_time())
			move_and_slide()
			back_timer -= get_process_delta_time()
			await get_tree().process_frame

	# slide to stop after attack
	velocity = velocity.move_toward(Vector2.ZERO, friction * get_process_delta_time())
