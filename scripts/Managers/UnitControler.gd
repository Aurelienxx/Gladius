extends Node2D

@export var unit_tank : PackedScene = preload("res://scenes/Entities/Units/TankUnit.tscn")
@export var unit_infantry : PackedScene = preload("res://scenes/Entities/Units/Infantry.tscn")
@export var spawn_count: int = 8            
@export var spawn_radius: float = 100.0     # distance autour du point


func _ready() -> void:
	for i in range(spawn_count):
			var angle = float(i) / spawn_count * TAU   # répartis en cercle
			var offset = Vector2(cos(angle), sin(angle)) * spawn_radius

			if i % 2 == 0:
				var tank = unit_tank.instantiate()
				add_child(tank)
				tank.setup(1)
				tank.position = position + offset
			else:
				var infantry = unit_infantry.instantiate()
				infantry.setup(2)  # équipe 2
				infantry.position = position + offset
				add_child(infantry)
