extends CharacterBody2D

@export var speed := 220
@export var turn_delay := 1
@export var dash_speed := 450        # how fast the dash goes
@export var dash_time := 0.25        # how long the dash lasts
#@export var detection_range := 200 

@onready var ray_wall = $Rays/RayWall
@onready var ray_ledge = $Rays/RayLedge
@onready var sprite = $Sprite
@onready var rays: Node2D = $Rays
@onready var detect_area = $Rays/PlayerDetect
@onready var hitbox: Area2D = $Rays/Hitbox

var dir := -1
var turning := false
var attacking := false
var player_ref = null

var can_attack_on_beat := false

func _ready():
	detect_area.body_entered.connect(_on_player_detect)
	detect_area.body_exited.connect(_on_player_exit)

	# connect to beat
	BeatManager.beat_window.connect(_on_beat_window)

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y += 1200 * delta
	
	if attacking:
		return  # ignore walking + flipping while dashing/attacking

	if not turning:
		velocity.x = -dir * speed
		sprite.play("Walk")
	else:
		velocity.x = 0
		sprite.play("Idle")

	if Dialogic.current_timeline == null:
		move_and_slide()

	if not turning and not attacking:
		if ray_wall.is_colliding() or not ray_ledge.is_colliding():
			start_turning()

func start_turning() -> void:
	turning = true
	velocity.x = 0
	turn_after_delay()

func turn_after_delay() -> void:
	await get_tree().create_timer(turn_delay).timeout
	flip_direction()
	await get_tree().create_timer(0.1).timeout
	turning = false

func flip_direction():
	if attacking: return
	dir *= -1
	sprite.scale.x = abs(sprite.scale.x) * dir
	rays.scale.x = abs(rays.scale.x) * dir

## -----------------------------
##   PLAYER DETECTION + ATTACK
## -----------------------------

var queued_attack := false

func _on_player_detect(body):
	if body.is_in_group("player"):
		player_ref = body
		queued_attack = true

func _on_beat_window():
	if queued_attack:
		queued_attack = false
		$AudioStreamPlayer.play()
		if player_ref:
			attack_player()

func _on_player_exit(_body):
	pass
	#if body == player_ref:
		#player_ref = null

func attack_player() -> void:
	
	if !get_tree(): return
	
	if attacking or turning or player_ref == null:
		return

	attacking = true
	velocity = Vector2.ZERO

	# play attack anim
	sprite.play("Attack")

	await get_tree().create_timer(0.4).timeout  # wind-up
	hitbox.monitoring = true
	detect_area.monitoring = false

	if player_ref == null:
		attacking = false
		return

	# face player
	var direction_to_player = sign(player_ref.global_position.x - global_position.x)
	dir = -direction_to_player
	sprite.scale.x = abs(sprite.scale.x) * dir
	rays.scale.x = abs(rays.scale.x) * dir

	# dash
	var dash_dir = Vector2(dir, 0)
	var dash_timer = dash_time
	

	while sprite.is_playing():
		if !get_tree(): return
		velocity.x = -dash_dir.x * dash_speed
		move_and_slide()
		dash_timer -= get_process_delta_time()
		await get_tree().process_frame

	# reset after dash
	velocity.x = 0
	attacking = false
	hitbox.monitoring = false
	detect_area.monitoring = true
