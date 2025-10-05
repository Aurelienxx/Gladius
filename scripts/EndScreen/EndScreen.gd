extends CanvasLayer

@onready var result = $Panel/VBoxContainer/Result

func _on_main_menu_pressed() -> void:
	"""
	Reprend le jeu et retourne au menu principal.
	"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
	
func change_result(team: int):
	"""
	Affiche le résultat de la partie selon l’équipe gagnante.
	
	:param team: (int) Numéro de l’équipe gagnante (1 = bleu, autre = rouge).
	"""
	if team == 1:
		result.text = "L'équipe bleu a gagné !"
		result.modulate = Color.BLUE
	else:
		result.text = "L'équipe rouge a gagné !"
		result.modulate = Color.RED
		


func _on_exit_button_pressed() -> void:
	"""
	Quitte le jeu proprement.
	"""
	get_tree().quit()
