extends Node

@onready var building_body: Node2D = get_parent() # le batiment
@export var area2D : Area2D

var is_selected: bool = false

func _ready() -> void:
	"""
	Connecte les signaux globaux et locaux :
	- Unit_Clicked : désélectionne le batiment si un autre est sélectionné
	- clicked / attack_clicked : interactions directes sur la zone cliquable
	"""
	GlobalSignal.Unit_Clicked.connect(_on_building_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_building_clicked(unit):
	"""
	Désélectionne ce batiment si un autre est sélectionné.
	"""
	if unit != building_body:
		is_selected = false

func _on_shape_clicked():
	"""
	Sélectionne ce batiment lorsqu’il est cliqué avec le clic gauche
	et envoie un signal global pour notifier la sélection.
	"""
	print(building_body.current_hp)
	is_selected = true
	GlobalSignal.Building_CLicked.emit(building_body)
	# _show_hq_ui()  # Affichage de l'UI du batiment 

func _on_shape_attack_clicked():
	"""
	Émet un signal global lorsqu’un clic droit est fait sur le batiment,
	permettant à d’autres entités de réagir (ex : attaque).
	"""
	pass
	#GlobalSignal.Unit_Attack_Clicked.emit(building_body, null)


func _show_hq_ui():
	"""
	Affiche le menu spécifique du batiment (ressources, production, améliorations...).
	"""
	pass
