extends Node

@onready var villageTown_body: Node2D = get_parent() 
@export var area2D : Area2D 

var is_selected: bool = false

func _ready() -> void:
	GlobalSignal.Unit_Clicked.connect(_on_village_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_village_clicked(unit):
	if unit != villageTown_body:
		is_selected = false

func _on_shape_clicked():
	is_selected = true
	GlobalSignal.Unit_Clicked.emit(villageTown_body)
	#_show_villagetown_ui() # par exemple ouvrir le menu d'amélioration 

func _on_shape_attack_clicked():
	GlobalSignal.Unit_Attack_Clicked.emit(villageTown_body, null)
	# Ici tu peux gérer une attaque sur le village, si c'est prévu

func _show_villagetown_ui():
	# Code pour afficher l'UI des villages et villes : production, ressources, etc.
	pass
