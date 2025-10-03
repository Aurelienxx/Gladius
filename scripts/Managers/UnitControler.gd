extends Node2D

@export var unit_truck : PackedScene = preload("res://scenes/Entities/Units/TruckUnit.tscn")
@export var unit_artillery : PackedScene = preload("res://scenes/Entities/Units/ArtilleryUnit.tscn")
@export var unit_tank : PackedScene = preload("res://scenes/Entities/Units/TankUnit.tscn")
@export var unit_infantry : PackedScene = preload("res://scenes/Entities/Units/Infantry.tscn")
@export var headquarter : PackedScene = preload("res://scenes/Entities/Building/QG.tscn")
@export var village : PackedScene = preload("res://scenes/Entities/Building/Village.tscn")

@export var spawn_count: int = 8            
@export var spawn_radius: float = 100.0     # distance autour du point

@export var head_quarter : PackedScene = preload("res://scenes/Entities/Building/QG.tscn")
@export var qg_positions: Array[Vector2] = [Vector2(200, 200), Vector2(800, 200)]
@export var village_positions :  Array[Vector2] = [Vector2(400, 400), Vector2(60, 60)]



func _ready() -> void:
	var tilemap = get_node("../../TileMapContainer/TileMap_Dirt")
	for i in range(qg_positions.size()):
		var qg = head_quarter.instantiate()
		qg.add_to_group("buildings")
		qg.call_deferred("setup", i + 1)

		var qg_pos = qg_positions[i]

		var cell = tilemap.local_to_map(tilemap.to_local(qg_pos))

		var snapped_pos = tilemap.map_to_local(cell)
		qg.position = tilemap.position + snapped_pos

		add_child(qg)
		
	for i in range(village_positions.size()):
		var vlg = village.instantiate()
		vlg.add_to_group("buildings")
		vlg.call_deferred("setup", 0)

		var qg_pos = village_positions[i]

		var cell = tilemap.local_to_map(tilemap.to_local(qg_pos))

		var snapped_pos = tilemap.map_to_local(cell)
		vlg.position = tilemap.position + snapped_pos

		add_child(vlg)



func spawn_unit(unit_type: String, actual_player: int):
	var tilemap = get_node("../../TileMapContainer/TileMap_Dirt")
	var used_cells = tilemap.get_used_cells()
	var unit
	
	var qg_pos = qg_positions[actual_player - 1]
	var qg_cell = tilemap.local_to_map(tilemap.to_local(qg_pos))
	
	if tilemap.tile_set == null:
		push_error("Le TileMap n’a pas de TileSet assigné !")
		return null
	
	var tile_size = float(tilemap.tile_set.tile_size.x) 
	var radius_in_cells = int(spawn_radius / tile_size) + 1.5
	
	var cells: Array[Vector2i] = []
	for x in range(-radius_in_cells + 1, radius_in_cells):
		for y in range(-radius_in_cells + 1, radius_in_cells):
			var candidate = qg_cell + Vector2i(x, y)
			if qg_cell.distance_to(candidate) <= radius_in_cells:
				if used_cells.has(candidate):
					cells.append(candidate)
					
	var occupied_positions = []
	for current_unit in get_tree().get_nodes_in_group("units"):
		var cell_pos = tilemap.local_to_map(tilemap.to_local(current_unit.position))
		occupied_positions.append(cell_pos)
		
	occupied_positions.append(tilemap.local_to_map(tilemap.to_local(qg_pos)))
	
	var offsets = [
	Vector2(32, 0), Vector2(-32, 0),
	Vector2(0, 32), Vector2(0, -32),
	Vector2(32, 32), Vector2(32, -32),
	Vector2(-32, 32), Vector2(-32, -32)
	]

	for offset in offsets:
		var new_pos = qg_pos + offset
		occupied_positions.append(tilemap.local_to_map(tilemap.to_local(new_pos)))
		
	var free_cells = []
	for current_cell in cells:
		if current_cell not in occupied_positions:
			free_cells.append(current_cell)
			
	if free_cells.is_empty():
		return null
	
	var cell = free_cells[randi() % free_cells.size()]
	match unit_type:
		"Tank": unit = unit_tank.instantiate()
		"Infantry": unit = unit_infantry.instantiate()
		"Truck": unit = unit_truck.instantiate()
		"Artillery": unit = unit_artillery.instantiate()
		_: return null
	
	unit.call_deferred("setup", actual_player)
	unit.add_to_group("units")
	
	
	var local_pos = tilemap.map_to_local(cell)
	unit.position = tilemap.to_global(local_pos)
	return unit
