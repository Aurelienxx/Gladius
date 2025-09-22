extends CharacterBody2D

# Stats de base (communes à toutes les unités de ce type)
@export var cost: int = 60
@export var maintenance: int = 3
@export var max_hp: int = 150
@export var damage: int = 30
@export var move_range: int = 10
@export var attack_range: int = 3  

# État de l’unité (spécifique à chaque instance)
var current_hp: int
var equipe: int

func setup(_equipe: int) -> void:
	equipe = _equipe
	current_hp = max_hp
