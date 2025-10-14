extends Area2D

signal clicked        # Signal émis lors d’un clic gauche, connecté à _on_unit_clicked() dans main.gd
signal attack_clicked # Signal émis lors d’un clic droit, connecté à _on_unit_attack() dans main.gd


func _ready():
	"""
	Connexion du signal d’entrée de la souris à la fonction de gestion des clics.
	"""
	self.input_event.connect(_on_input_event)

func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:	
	"""
	Gère les clics de souris sur l’Area2D.
	Émet un signal différent selon le bouton cliqué.

	:param viewport: (Viewport) La fenêtre dans laquelle l’événement a eu lieu.
	:param event: (InputEvent) L’événement d’entrée détecté (clic de souris).
	:param shape_idx: (int) Index de la forme de collision qui a déclenché l’événement.
	:return: None
	"""
	if Input.is_action_just_released("leftClick"): 
		emit_signal("clicked")
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		emit_signal("attack_clicked")
