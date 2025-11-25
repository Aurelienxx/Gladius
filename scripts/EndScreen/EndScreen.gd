extends CanvasLayer

@onready var result = $VBoxContainer/MarginContainer/VBoxContainer2/VBoxContainer/Result

func _on_main_menu_pressed() -> void:
	"""
	Reprend le jeu et retourne au menu principal.
	"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
	
func change_result():
	"""
	Affiche le résultat de la partie selon l’équipe gagnante.
	
	:param team: (int) Numéro de l’équipe gagnante (1 = bleue, autre = rouge).
	"""
	if GameState.current_player == 2:
		result.text = "L'équipe rouge a gagné !"
		result.modulate = Color.RED
	else:
		result.text = "L'équipe bleue a gagné !"
		result.modulate = Color.BLUE

func _on_exit_button_pressed() -> void:
	"""
	Quitte le jeu proprement.
	"""
	get_tree().quit()
