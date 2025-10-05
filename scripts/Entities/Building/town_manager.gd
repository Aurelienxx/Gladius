extends Node

@onready var villageTown_body: Node2D = get_parent() 
@export var area2D : Area2D 

var is_selected: bool = false

func _ready() -> void:
	"""
	Connecte les signaux globaux et locaux :
	- Unit_Clicked : désélectionne ce village si un autre est sélectionné
	- clicked / attack_clicked : interactions directes sur la zone cliquable
	"""
	GlobalSignal.Unit_Clicked.connect(_on_village_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_village_clicked(unit):
	"""
	Désélectionne ce village si un autre est sélectionné.
	"""
	if unit != villageTown_body:
		is_selected = false

func _on_shape_clicked():
	"""
	Sélectionne ce village lorsqu’il est cliqué avec le clic gauche
	et envoie un signal global pour notifier la sélection.
	"""
	is_selected = true
	GlobalSignal.Unit_Clicked.emit(villageTown_body)
	# _show_villagetown_ui()  # Affichage de l'UI du village 

func _on_shape_attack_clicked():
	"""
	Émet un signal global lorsqu’un clic droit est fait sur le village,
	permettant à d’autres entités de réagir (ex : attaque).
	"""
	GlobalSignal.Unit_Attack_Clicked.emit(villageTown_body, null)


func _show_villagetown_ui():
	"""
	Affiche le menu spécifique du village (ressources, production, améliorations...).
	"""
	pass
