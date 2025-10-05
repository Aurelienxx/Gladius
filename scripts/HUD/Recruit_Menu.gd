extends VBoxContainer

@export var targetContainer :VBoxContainer

func toggleVisibility(object: Control) -> void:
	"""
	Bascule la visibilité d’un objet entre visible et caché.

	:param object: (Control) Objet dont on change la visibilité.
	:return: None
	"""
	if object.visible:
		object.visible = false
	else:
		object.visible = true


func _on_toggle_button_pressed() -> void:
	"""
	Appelé lors de l’appui sur le bouton lié.
	Inverse la visibilité du conteneur cible.
	"""
	toggleVisibility(targetContainer)
