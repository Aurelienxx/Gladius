extends Control

@export var KeyBinds: NinePatchRect

func _ready() -> void:
	GlobalSignal.showGameModeButtons.connect(displayButtons)


func displayButtons():
	KeyBinds.visible = true


func _on_leave_pressed() -> void:
	"""
	Retour au menu principal depuis le menu de choix de jeu.
	"""
	visible = false
	GlobalSignal.showMainButtons.emit()

# Lien vers le document utilisateur 
func on_docu_button_pressed():
	"""
	Redirige vers la documentation utilisateur
	"""
	OS.shell_open("https://aurelienxx.github.io/Gladius/userNotice.html")
