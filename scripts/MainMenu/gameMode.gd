extends Control

@export var teamChoice: Control
@export var gameModes: NinePatchRect

func _ready() -> void:
	GlobalSignal.showGameModeButtons.connect(displayButtons)

# Choix de jeu
func _on_joueur_contre_joueur_pressed() -> void:
	"""
	Lance une partie en mode Joueur contre Joueur.
	"""
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/Map/map.tscn")
	
func _on_joueur_contre_ia_pressed() -> void:
	"""
	Prévu pour lancer une partie en mode Joueur contre IA.
	"""
	gameModes.visible = false
	teamChoice.visible = true
	
func _on_ia_contre_ia_pressed() -> void:
	"""
	Prévu pour lancer une partie en mode IA contre IA.
	"""
	GameState.switch_player_to_ai(1)
	GameState.switch_player_to_ai(2)
	get_tree().change_scene_to_file("res://scenes/Map/map.tscn")

func _on_back_button_pressed() -> void:
	"""
	Retour au menu principal depuis le menu de choix de jeu.
	"""
	visible = false
	GlobalSignal.showMainButtons.emit()

func displayButtons():
	gameModes.visible = true
