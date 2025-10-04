extends Node

@onready var hq_body: Node2D = get_parent() # le QG
@export var area2D : Area2D

var is_selected: bool = false

func _ready() -> void:
	"""
	Connecte les signaux globaux et locaux :
	- Unit_Clicked : désélectionne le QG si un autre est sélectionné
	- clicked / attack_clicked : interactions directes sur la zone cliquable
	"""
	GlobalSignal.Unit_Clicked.connect(_on_hq_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_hq_clicked(unit):
	"""
	Désélectionne ce QG si un autre est sélectionné.
	"""
	if unit != hq_body:
		is_selected = false

func _on_shape_clicked():
	"""
	Sélectionne ce QG lorsqu’il est cliqué avec le clic gauche
	et envoie un signal global pour notifier la sélection.
	"""
	is_selected = true
	GlobalSignal.Unit_Clicked.emit(hq_body)
	# _show_hq_ui()  # Affichage de l'UI du QG 

func _on_shape_attack_clicked():
	"""
	Émet un signal global lorsqu’un clic droit est fait sur le QG,
	permettant à d’autres entités de réagir (ex : attaque).
	"""
	GlobalSignal.Unit_Attack_Clicked.emit(hq_body, null)


func _show_hq_ui():
	"""
	Affiche le menu spécifique du QG (ressources, production, améliorations...).
	"""
	pass
