extends Node2D

@export var unit_scene : PackedScene = preload("res://scenes/Entities/Units/TankUnit.tscn")        # ta scène d'unité (ex: res://Unit.tscn)
@export var spawn_count: int = 8            
@export var spawn_radius: float = 100.0     # distance autour du point


func _ready() -> void:
	
	for i in range(spawn_count):
		var unit = unit_scene.instantiate()
		unit.setup((i%2)+1)
		
		var angle = 0.0
		
		if randomize:
			angle = randf() * TAU   # angle aléatoire
		else:
			angle = float(i) / spawn_count * TAU   # répartis en cercle
		
		var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
		unit.position = position + offset   # spawn autour de ce Node2D
		add_child(unit)
