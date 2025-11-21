extends Control

@export var line_template_path : NodePath = NodePath("LineTemplate")
@export var lane_speed_multiplier := 1.0  # tweak if needed

@onready var line_template = get_node(line_template_path)
var beat_lines := []

func _ready():
	line_template.visible = false
	BeatManager.connect("beat", Callable(self, "_on_beat"))

func _on_beat():
	# spawn a line off-screen left
	var line = line_template.duplicate()
	line.visible = true
	add_child(line)

	var spawn_x = -line_template.size.x * 2
	line.position.x = spawn_x

	# store speed so it crosses center exactly on beat
	line.speed = (size.x / 2.0 - spawn_x) / BeatManager.seconds_per_beat * lane_speed_multiplier

	beat_lines.append(line)

func _process(delta):
	for line in beat_lines:
		line.position.x += line.speed * delta

		# check if the line is crossing center (this is the beat moment)
		#if line.position.x - line.speed * delta < size.x / 2.0 <= line.position.x:
			# line is now crossing center, can trigger visual/audio if needed
		#	pass

		# remove if fully off-screen
		if line.position.x > size.x + 200:
			line.queue_free()

	# cleanup
	beat_lines = beat_lines.filter(func(l):
		return not l.is_queued_for_deletion())
