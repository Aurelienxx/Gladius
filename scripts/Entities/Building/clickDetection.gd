extends Area2D

# Signaux émis lors des clics de souris
signal clicked            # Clic gauche
signal attack_clicked     # Clic droit


func _input_event(viewport, event, shape_idx):
	"""
	Gère les interactions de la souris sur l’Area2D :
	- Émet 'clicked' si le joueur clique gauche.
	- Émet 'attack_clicked' si le joueur clique droit.

	:param viewport: (Viewport) Vue dans laquelle se produit l’événement.
	:param event: (InputEvent) Événement de saisie détecté.
	:param shape_idx: (int) Index de la forme cliquée dans l’Area2D.
	:return: None
	"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("attack_clicked")
