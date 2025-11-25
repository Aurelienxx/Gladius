extends Area2D

signal clicked        # Signal émis lors d’un clic gauche, connecté à _on_unit_clicked() dans main.gd
signal attack_clicked # Signal émis lors d’un clic droit, connecté à _on_unit_attack() dans main.gd


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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		emit_signal("clicked")
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		emit_signal("attack_clicked")
