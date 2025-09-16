extends Node2D
class_name Entities

var hp: int
var sprite: Sprite2D

func _init(_hp: int = 100, _texture: Texture2D = null):
	hp = _hp

	# Création du sprite
	sprite = Sprite2D.new()
	if _texture != null:
		sprite.texture = _texture
	add_child(sprite)

func get_damage(damage: int) -> void:
	hp = max(hp - damage, 0)
	print("HP restants = ", hp)
