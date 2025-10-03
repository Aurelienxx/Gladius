extends Control

@onready var result = $Panel/VBoxContainer/Result

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
	
func change_result(team: int):
	if team == 1:
		result.text = "L'équipe bleu a gagné !"
		result.modulate = Color.BLUE
	else:
		result.text = "L'équipe rouge a gagné !"
		result.modulate = Color.RED
		
