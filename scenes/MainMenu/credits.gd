extends Control

@export var credits: NinePatchRect

func _ready() -> void:
	GlobalSignal.showGameModeButtons.connect(displayButtons)

func displayButtons():
	credits.visible = true

func _on_leave_pressed() -> void:
	"""
	Retour au menu principal depuis le menu de choix de jeu.
	"""
	visible = false
	GlobalSignal.showMainButtons.emit()
