extends Node

@onready var character: CharacterBody2D = get_parent()
@export var area2D : Area2D 
@export var move_speed: float = 200.0
@export var MaskOverlay:AnimatedSprite2D
@export var anim:AnimatedSprite2D

var is_selected: bool = false
var path: Array = []
var target_position: Vector2
var is_moving: bool = false
var map_ref: TileMapLayer

func _ready() -> void:
	"""
	Connexion des signaux globaux et des clics de l’Area2D à leurs fonctions de gestion.
	"""
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_unit_clicked(unit):
	"""
	Désélectionne l'unité si une autre est sélectionnée.
	
	:param unit: (CharacterBody2D) L’unité qui a été cliquée.
	:return: None
	"""
	if unit != character:
		is_selected = false

func _on_shape_clicked():
	"""
	Sélectionne cette unité et envoie un signal global pour notifier la sélection.
	"""
	is_selected = true
	GlobalSignal.Unit_Clicked.emit(character)

func _on_shape_attack_clicked():
	"""
	Émet un signal global pour indiquer que l'unité est attaqué.
	"""
	GlobalSignal.Unit_Attack_Clicked.emit(character, null)

func set_path(new_path: Array, map: TileMapLayer):
	"""
	Assigne un nouveau chemin de déplacement et lance le mouvement.
	
	:param new_path: (Array) Liste des cellules à parcourir.
	:param map: (TileMapLayer) Référence à la carte pour convertir les cellules en positions.
	"""
	path = new_path
	map_ref = map
	move_to_next_cell()

func move_to_next_cell():
	if path.is_empty():
		is_moving = false
		return
	var next_cell: Vector2i = path.pop_front()
	target_position = map_ref.map_to_local(next_cell)
	is_moving = true

func _physics_process(delta: float) -> void:
	"""
	Gestion du mouvement de l’unité à chaque frame physique.
	Contrôle le déplacement, l’orientation du sprite et l’animation.
	
	:param delta: (float) Temps écoulé depuis la dernière frame physique.
	"""
	if is_moving:
		var direction = target_position - character.global_position
		if direction.length() > 2:
			character.velocity = direction.normalized() * move_speed
			character.move_and_slide()
			
			if character.velocity.x < 0:
				anim.flip_h = true
				MaskOverlay.flip_h = true
			elif character.velocity.x > 0:
				anim.flip_h = false
				MaskOverlay.flip_h = false
			
		else:
			character.global_position = target_position
			character.velocity = Vector2.ZERO
			is_moving = false
			move_to_next_cell()
	else:
		if anim:
			anim.play()
		if MaskOverlay:
			MaskOverlay.play()
		

func _capture_nearby_neutral_village():
	"""
	Cherche les villages neutres à proximité immédiate
	et les capture pour l’équipe de l’unité si possible.
	"""
	var unit_pos = character.global_position
	var radius = 1 # Taille de recherche autour de l'unité
	var villages = get_tree().get_nodes_in_group("Village") # Récupération des Villages
	for village in villages:
		if village.has_method("capture"):
			var v_pos = village.global_position
			if unit_pos.distance_to(v_pos) <= radius:
				if village.equipe == 0:
					print("Capture par équipe ", character.equipe)
					village.capture(character.equipe)
