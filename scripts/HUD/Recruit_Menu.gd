extends VBoxContainer

@export var targetContainer :VBoxContainer

func toggleVisibility(object):
	if object.visible :
		object.visible = false
	else:
		object.visible = true


func _on_toggle_button_pressed() -> void:
	toggleVisibility(targetContainer)
