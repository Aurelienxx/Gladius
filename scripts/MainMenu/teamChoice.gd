extends Control

func _on_team_bleue_pressed() -> void:
	GameState.switch_player_to_ai(2)
	get_tree().change_scene_to_file("res://scenes/Map/map.tscn")  

func _on_team_rouge_pressed() -> void:
	GameState.switch_player_to_ai(1)
	get_tree().change_scene_to_file("res://scenes/Map/map.tscn")  

func _on_retour_pressed() -> void:
	visible = false
	GlobalSignal.showGameModeButtons.emit()
