extends AnimatedSprite2D

func _ready() -> void:
	self.play()
	self.animation_finished.connect(_on_finished)

func _on_finished():
	print("hello")
	self.visible = false
	queue_free()  
