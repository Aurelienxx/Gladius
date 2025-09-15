extends Node2D
class_name Entities

# Statistiques
var hp: int
var sprite: String

var current_hp: int


# Initalisation des statistiques de l'unité
func _init(
		_hp: int = 0,
		_sprite: String = "res://assets/sprites/cotar.png",
	):
	hp = _hp
	current_hp = _hp
	sprite = _sprite

# Fonction de dégats
func get_damage(damages: int) -> void:
	current_hp = max(current_hp - damages, 0)
