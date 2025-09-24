extends Node

@onready var hq_body: Node2D = get_parent() # le QG
@export var area2D : Area2D 

var is_selected: bool = false

func _ready() -> void:
	GlobalSignal.Unit_Clicked.connect(_on_hq_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_hq_clicked(unit):
	if unit != hq_body:
		is_selected = false

func _on_shape_clicked():
	is_selected = true
	GlobalSignal.Unit_Clicked.emit(hq_body)
	#_show_hq_ui() # par exemple ouvrir le menu du QG

func _on_shape_attack_clicked():
	GlobalSignal.Unit_Attack_Clicked.emit(hq_body, null)
	# Ici tu peux gérer une attaque sur le QG, si c'est prévu

func _show_hq_ui():
	# Code pour afficher l'UI du QG : production, ressources, etc.
	pass
