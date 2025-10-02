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
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_unit_clicked(unit):
	if unit != character:
		is_selected = false

func _on_shape_clicked():
	is_selected = true
	GlobalSignal.Unit_Clicked.emit(character)

func _on_shape_attack_clicked():
	GlobalSignal.Unit_Attack_Clicked.emit(character, null)

func set_path(new_path: Array, map: TileMapLayer):
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
	# Recherche les villages dans le voisinage immédiat
	var unit_pos = character.global_position
	var radius = 1 # à ajuster selon la taille des cases
	var villages = get_tree().get_nodes_in_group("Village")
	for village in villages:
		if village.has_method("capture"):
			var v_pos = village.global_position
			if unit_pos.distance_to(v_pos) <= radius:
				if village.equipe == 0:
					print("Capture par équipe ", character.equipe)
					village.capture(character.equipe)
