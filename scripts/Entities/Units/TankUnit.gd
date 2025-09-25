class_name TankUnit
extends CharacterBody2D

# Stats de base (communes à toutes les unités de ce type)
@onready var couleur : PointLight2D = $AnimatedSprite2D/PointLight2D
@export var cost: int = 150
@export var maintenance: int = 5
@export var max_hp: int = 400
@export var damage: int = 80
@export var move_range: int = 5
@export var attack_range: int = 4  
@export var movement: bool = false
@export var attack: bool = false

# État de l’unité (spécifique à chaque instance)
var current_hp: int
var equipe: int

func setup(_equipe: int) -> void:
	equipe = _equipe
	current_hp = max_hp
	if (_equipe == 1):
		couleur.color = Color(0, 0, 1, 0.75)
		print("test bleu")
	else:
		couleur.color = Color(1, 0, 0, 0.75)
		print("test bleu")

func _ready():
	setup(1)
