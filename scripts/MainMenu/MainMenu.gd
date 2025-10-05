extends Control
@export var buttons: VBoxContainer 
@export var settings: VBoxContainer 
@export var gamechoice: VBoxContainer

func _ready():
	"""
	Initialise l’écran du menu principal.
	Affiche les boutons de base et cache les autres panneaux.
	"""
	settings.visible = false
	buttons.visible = true
	gamechoice.visible = false
	

# Bouton "Jouer"
func _on_start_button_pressed() -> void:
	"""
	Affiche le menu de choix de mode de jeu
	et masque les boutons principaux.
	"""
	gamechoice.visible = true
	buttons.visible = false


# Choix de jeu
func _on_joueur_contre_joueur_pressed() -> void:
	"""
	Lance une partie en mode Joueur contre Joueur.
	"""
	get_tree().change_scene_to_file("res://scenes/Map/map.tscn")
	
func _on_joueur_contre_ia_pressed() -> void:
	"""
	Prévu pour lancer une partie en mode Joueur contre IA.
	"""
	pass  
	
func _on_ia_contre_ia_pressed() -> void:
	"""
	Prévu pour lancer une partie en mode IA contre IA.
	"""
	pass  

func _on_back_choice_pressed() -> void:
	"""
	Retour au menu principal depuis le menu de choix de jeu.
	"""
	gamechoice.visible = false
	buttons.visible = true


# Paramètres
func _on_parameters_button_pressed() -> void:
	"""
	Affiche le menu des paramètres
	et masque les boutons principaux.
	"""
	settings.visible = true

func _on_settings_visibility_changed() -> void:
	if not buttons.visible:
		print("hello")
		buttons.visible = true
	else:
		print("bye")
		buttons.visible = false
		
func _on_back_parameters_pressed() -> void:
	"""
	Retour au menu principal depuis le menu des paramètres.
	"""
	settings.visible = false
	buttons.visible = true


# Quitter le jeu 
func _on_exit_button_pressed():
	"""
	Quitte le jeu proprement.
	"""
	get_tree().quit()
