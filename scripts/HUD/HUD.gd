extends CanvasLayer


func _on_button_button_down() -> void:
	# 'next turn' button is pressed 
	GlobalSignal.Next_Turn_Pressed.emit()
