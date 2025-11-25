extends AnimatedSprite2D

@onready var exp_snd: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	self.play()
	self.animation_finished.connect(_on_finished)
	
func _on_finished():
	self.visible = false
	queue_free()
