extends Node

signal beat()        # fired exactly on beat
signal beat_window() # fired slightly before/after beat for player input

@onready var music_player = $MusicPlayer
@onready var effect: AnimatedSprite2D = $BeatUI/Effect

var last_beat = -1

var bpm = 150
var seconds_per_beat = 0.0

var beat_timer = 0.0
var window_size = 0.2   # how forgiving the timing is (120ms)
var song_offset = 0.0    # use if the song starts a little late

var fade_speed = 1.5   # how fast it fades in

func play_song(stream: AudioStreamMP3):
	beat_timer = 0.0
	music_player.stream = stream
	music_player.volume_db = -40
	music_player.play(song_offset)
	seconds_per_beat = 60.0 / stream.bpm

	var fade_tween = get_tree().create_tween()

	# fade in using tween
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -10.0, fade_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_song():
	if not music_player.playing:
		return

	var fade_out = create_tween()
	fade_out.tween_property(music_player, "volume_db", -80.0, fade_speed/2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_callback(Callable(music_player, "stop"))

var window_active = false
var window_timer = 0.0

func _process(delta):
	if not music_player.playing:
		return

	var pos = music_player.get_playback_position()

	# exact beat number using audio time
	var beat_pos = pos / seconds_per_beat

	# detect beat (integer crossing)
	var current_beat = int(beat_pos)

	if current_beat != last_beat:
		last_beat = current_beat
		emit_signal("beat")

	# beat window (early / late)
	var distance_to_nearest = abs(beat_pos - round(beat_pos))
	if distance_to_nearest <= window_size:
		emit_signal("beat_window")
		#print("BEAT")
