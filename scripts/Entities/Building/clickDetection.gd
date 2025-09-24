extends Area2D

signal clicked
signal attack_clicked
signal headquarter_clicked

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("attack_clicked")
