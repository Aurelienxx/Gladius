extends AnimatedSprite2D

@onready var exp_snd: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	play()
func _on_finished() -> void:
	print("hello")
	visible = false
	queue_free()
