extends Node2D

@export var unit_tank : PackedScene = preload("res://scenes/Entities/Units/TankUnit.tscn")
@export var unit_infantry : PackedScene = preload("res://scenes/Entities/Units/Infantry.tscn")
@export var headquarter : PackedScene = preload("res://scenes/Entities/Building/QG.tscn")
@export var spawn_count: int = 8            
@export var spawn_radius: float = 100.0     # distance autour du point

@export var head_quarter : PackedScene = preload("res://scenes/Entities/Building/QG.tscn")
@export var qg_positions: Array[Vector2] = [Vector2(200, 200), Vector2(800, 200)]


func _ready() -> void:
	for i in range(spawn_count):
			var angle = float(i) / spawn_count * TAU   # répartis en cercle
			var offset = Vector2(cos(angle), sin(angle)) * spawn_radius

			if i % 2 == 0:
				var tank = unit_tank.instantiate()
				tank.add_to_group("units")
				tank.setup(1)  # équipe 1
				tank.position = position + offset
				add_child(tank)
				tank.setup(1)
				tank.position = position + offset
			else:
				var infantry = unit_infantry.instantiate()
				infantry.add_to_group("units")
				infantry.setup(2)  # équipe 2
				infantry.position = position + offset
				add_child(infantry)
				
	for i in range(qg_positions.size()):
		var qg = head_quarter.instantiate()
		qg.add_to_group("buildings")
		qg.setup(i + 1)
		qg.position = qg_positions[i]
		add_child(qg)
