extends Control
@export var buttons: VBoxContainer 
@export var settings: Control 
@export var gamechoice: Control

func _ready():
	"""
	Initialise l’écran du menu principal.
	Affiche les boutons de base et cache les autres panneaux.
	"""
	settings.visible = false
	buttons.visible = true
	gamechoice.visible = false
	GlobalSignal.showMainButtons.connect(displayButtons)

# Bouton "Jouer"
func _on_start_button_pressed() -> void:
	"""
	Affiche le menu de choix de mode de jeu
	et masque les boutons principaux.
	"""
	gamechoice.visible = true
	buttons.visible = false  

# Paramètres
func _on_parameters_button_pressed() -> void:
	"""
	Affiche le menu des paramètres
	et masque les boutons principaux.
	"""
	settings.visible = true
	buttons.visible = false

# Quitter le jeu 
func _on_exit_button_pressed():
	"""
	Quitte le jeu proprement.
	"""
	get_tree().quit()

func displayButtons():
	buttons.visible = true

# Afficher les contrôles
func _on_to_doc_pressed() -> void:
	"""
	Redirige vers la documentation utilisateur
	Affiche les contrôles du jeu
	"""
	OS.shell_open("https://aurelienxx.github.io/Gladius/userNotice.html")
