extends Control

@export var line_template_path : NodePath = NodePath("LineTemplate")
@export var lane_speed_multiplier := 1.0
@export var stop_duration := 0.07   # how long the line stops at center

@onready var line_template = get_node(line_template_path)
var beat_lines := []

func _ready():
	line_template.visible = false
	BeatManager.connect("beat", Callable(self, "_on_beat"))

func _on_beat():
	var line = line_template.duplicate()
	line.visible = true
	add_child(line)

	var spawn_x = -line_template.size.x * 2
	line.position.x = spawn_x

	# compute speed so it crosses CENTER on the beat
	var center_x = size.x / 2.0
	line.speed = (center_x - spawn_x) / BeatManager.seconds_per_beat * lane_speed_multiplier

	# extra data for stop behavior
	line.center_x = center_x
	line.stopped = false
	line.stop_timer = 0.0

	beat_lines.append(line)

func _process(delta):
	for line in beat_lines:

		# 1. BEFORE CENTER - normal movement
		if not line.stopped:
			var old_x = line.position.x
			line.position.x += line.speed * delta

			# did we hit or cross the center?
			if old_x < line.center_x and line.position.x >= line.center_x:
				line.position.x = line.center_x
				line.stopped = true
				line.stop_timer = stop_duration

			continue

		# 2. AT CENTER - freeze
		if line.stopped:
			line.stop_timer -= delta

			if line.stop_timer <= 0.0:
				line.stopped = false   # resume movement
			else:
				continue

		# 3. AFTER CENTER - continue same speed
		line.position.x += line.speed * delta

		# off-screen cleanup
		if line.position.x > size.x + 200:
			line.queue_free()

	beat_lines = beat_lines.filter(func(l):
		return not l.is_queued_for_deletion())
