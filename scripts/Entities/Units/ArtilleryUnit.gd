class_name ArtilleryUnit
extends CharacterBody2D

# Stats de base (communes à toutes les unités de ce type)
@onready var couleur : PointLight2D = $AnimatedSprite2D/PointLight2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D

@export var cost: int = 90
@export var maintenance: int = 3
@export var max_hp: int = 300
@export var damage: int = 75
@export var move_range: int = 2
@export var attack_range: int = 7  
@export var movement: bool = false
@export var attack: bool = false
@export var name_Unite: String = "Artillery"
@export var thumbnail: Texture2D

# État de l’unité (spécifique à chaque instance)
var current_hp: int
var equipe: int

func setup(_equipe: int) -> void:
	equipe = _equipe
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	
	if equipe == 2:
		anim.flip_h = true	
	
	_apply_color()  

func _ready():
	_apply_color() 

func _apply_color() -> void:
	if not couleur:
		return

	if equipe == 1:
		couleur.color = Color(0, 0, 1, 1.0)
	elif equipe == 2:
		couleur.color = Color(1, 0.0, 0.0, 1.0)
