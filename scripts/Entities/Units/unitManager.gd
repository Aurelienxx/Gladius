extends Node

@onready var character: CharacterBody2D = get_parent()
@onready var effectsPlayer = $"../Effects"

@export var area2D : Area2D 
@export var move_speed: float = 200.0
@export var MaskOverlay:AnimatedSprite2D
@export var anim:AnimatedSprite2D

var is_selected: bool = false
var is_attacking: bool = false

var path: Array = []
var target_position: Vector2
var is_moving: bool = false
var map_ref: TileMapLayer
var health_bar: ProgressBar

var hit_flash_timer: Timer
var base_modulate: Color

func init(_character: CharacterBody2D, _health_bar: ProgressBar, _anim: AnimatedSprite2D, _mask: AnimatedSprite2D, _map:TileMapLayer) -> void:
	"""
	Initialise les références entre le manager et les éléments de l’unité.

	:param _character: (CharacterBody2D) Référence au corps de l’unité.
	:param _health_bar: (ProgressBar) Barre de vie de l’unité.
	:param _anim: (AnimatedSprite2D) Sprite principal de l’unité.
	:param _mask: (AnimatedSprite2D) Sprite du masque coloré (couleur d’équipe).
	:return: None
	"""
	character = _character
	health_bar = _health_bar
	anim = _anim
	MaskOverlay = _mask
	map_ref = _map
	
	# Création et configuration du timer pour le flash de dégâts
	hit_flash_timer = Timer.new()
	hit_flash_timer.wait_time = 0.2
	hit_flash_timer.one_shot = true
	character.add_child(hit_flash_timer)
	hit_flash_timer.timeout.connect(_on_hit_flash_end)
	
	base_modulate = anim.modulate

func _ready() -> void:
	"""
	Connexion des signaux globaux et des clics de l’Area2D à leurs fonctions de gestion.
	"""
	area2D.clicked.connect(_on_shape_clicked)
	area2D.attack_clicked.connect(_on_shape_attack_clicked)

func _on_shape_clicked():
	"""
	Sélectionne cette unité et envoie un signal global pour notifier la sélection.
	"""
	is_selected = !is_selected
	GlobalSignal.Unit_Clicked.emit(character)
	if is_selected:
		effectsPlayer.play("pulse")

func _on_shape_attack_clicked():
	"""
	Émet un signal global pour indiquer que l'unité est attaqué.
	"""
	is_attacking = !is_attacking
	GlobalSignal.Unit_Attack_Clicked.emit(character)

func set_path(new_path: Array):
	"""
	Assigne un nouveau chemin de déplacement et lance le mouvement.
	
	:param new_path: (Array) Liste des cellules à parcourir.
	:param map: (TileMapLayer) Référence à la carte pour convertir les cellules en positions.
	"""
	path = new_path
	move_to_next_cell()

func move_to_next_cell():
	if path.is_empty():
		is_moving = false
		GlobalSignal.unit_finished_moving.emit()
		return
	var next_cell: Vector2i = path.pop_front()
	target_position = map_ref.map_to_local(next_cell)
	is_moving = true
	
func _apply_color(equipe : int) -> void:
	"""
	Applique une couleur selon l’équipe : bleu (1) ou rouge (2).
	"""
	var color:Color = Color("white")
	if equipe == 1:
		color = Color("Blue")
	else:
		color = Color("red")
	MaskOverlay.modulate = color

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
		
func update_health_bar(current_hp: int, max_hp: int) -> void:
	"""
	Met à jour la barre de vie et lance l’effet de flash sur le sprite.
	
	:param current_hp: (int) Points de vie actuels.
	:param max_hp: (int) Points de vie maximum.
	"""
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	anim.modulate = Color(2, 2, 2, 1)
	hit_flash_timer.start()

func _on_hit_flash_end() -> void:
	"""
	Restaure la couleur d’origine du sprite après le flash de dégâts.
	"""
	anim.modulate = base_modulate
