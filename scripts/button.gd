extends Button

@export var hover_scale := Vector2(1.2, 1.2)
@export var normal_scale := Vector2(1, 1)
@export var smooth_speed := 8.0


const HOVER_SOUND = preload("res://assets/ui-sounds-pack-5-19-359747.mp3")

var original_text := ""
var target_scale: Vector2
var audio_player: AudioStreamPlayer

func _ready() -> void:
	original_text = text
	target_scale = normal_scale
	scale = normal_scale

	
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "HoverSoundPlayer"
	audio_player.stream = HOVER_SOUND
	add_child(audio_player)

	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _process(delta: float) -> void:
	scale = scale.lerp(target_scale, delta * smooth_speed)

func _on_mouse_entered() -> void:
	target_scale = hover_scale
	text = "> " + original_text + " <"

	if audio_player.stream:
		audio_player.play()

func _on_mouse_exited() -> void:
	target_scale = normal_scale
	text = original_text
