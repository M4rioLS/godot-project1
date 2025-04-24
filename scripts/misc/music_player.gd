extends Node

@export var audio_stream: AudioStream
@export var volume_db: float = 0.0

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	if audio_stream:
		audio_player.stream = audio_stream
		audio_player.volume_db = volume_db
		audio_player.play()
	else:
		push_error("No audio stream assigned to MusicController")
	
	# Connect finished signal for seamless looping
	audio_player.finished.connect(_on_audio_finished)

func _on_audio_finished() -> void:
	audio_player.play()  # Loop the music

func play_music() -> void:
	if not audio_player.playing:
		audio_player.play()

func stop_music() -> void:
	audio_player.stop()

func set_volume(new_volume_db: float) -> void:
	audio_player.volume_db = new_volume_db
