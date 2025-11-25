extends CanvasLayer
signal finished

@export var label: Label 
@export var background: ColorRect 

func show_turn_async() -> void:
	label.text = "Tour du Joueur %d" % GameState.current_player
	background.modulate = Color(1, 1, 1, 0)
	visible = true

	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 0.4)
	await tween.finished

	await get_tree().create_timer(1.5).timeout

	tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 0.4)
	await tween.finished

	visible = false
	finished.emit()  
