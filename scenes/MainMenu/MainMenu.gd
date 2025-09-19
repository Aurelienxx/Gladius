extends Control
@onready var buttons: VBoxContainer = $Buttons
@onready var settings: Panel = $Settings
@onready var gamechoice: Panel = $GameChoice

func _ready():
	settings.visible = false
	buttons.visible = true
	gamechoice.visible = false
	
'''
Fonctions liées au bouton jouer.
'''
func _on_start_button_pressed() -> void:
	gamechoice.visible = true
	buttons.visible = false

'''
Fonctions liées aux boutons de choix de jeu.
'''
func _on_joueur_contre_joueur_pressed() -> void:
	#get_tree().change_scene_to_file()
	pass
	
func _on_joueur_contre_ia_pressed() -> void:
	pass # Replace with function body.
	
func _on_ia_contre_ia_pressed() -> void:
	pass # Replace with function body.

func _on_back_choice_pressed() -> void:
	gamechoice.visible = false
	buttons.visible = true

'''
Fonctions liées au bouton paramètres.
'''
func _on_parameters_button_pressed() -> void:
	settings.visible = true
	buttons.visible = false

func _on_back_parameters_pressed() -> void:
	settings.visible = false
	buttons.visible = true

'''
Fonctions liées au bouton paramètres.
'''
func _on_exit_button_pressed():
	get_tree().quit()
