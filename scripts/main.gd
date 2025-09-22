extends Node2D

var selected_unit: CharacterBody2D
var all_units: Array = []

func _ready():
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	for unit in $Units.get_children():
		all_units.append(unit)

func _on_unit_clicked(unit: CharacterBody2D):
	selected_unit = unit
	var map: TileMapLayer = $TileMapContainer/TileMap_Dirt
	var highlight: TileMapLayer = $TileMapContainer/TileMap_Highlight
	highlight.clear()
	if unit.is_selected:
		var start_cell = map.local_to_map(unit.global_position)
		var reachable_cells = get_reachable_cells(map, start_cell, unit.move_range)
		for cell in reachable_cells:
			var source_id_highlight = 0
			var atlas_cord_highlight = Vector2i(1,1) 
			highlight.set_cell(cell, source_id_highlight, atlas_cord_highlight)
		highlight.set_cells_terrain_connect(reachable_cells, 0, 0,false)

func get_reachable_cells(map: TileMapLayer, start: Vector2i, range: int) -> Array:
	var cells = []
	for x_offset in range(-range, range + 1):
		for y_offset in range(-range, range + 1):
			var cell = start + Vector2i(x_offset, y_offset)
			if not cell == start and abs(x_offset) + abs(y_offset) <= range:
				if map.get_cell_source_id(cell) != -1 and not is_cell_occupied(cell):
					cells.append(cell)
	return cells

func is_cell_occupied(cell: Vector2i) -> bool:
	for unit in all_units:
		var unit_cell = $TileMapContainer/TileMap_Dirt.local_to_map(unit.global_position)
		if unit_cell == cell:
			return true
	return false

func make_path(start: Vector2i, goal: Vector2i) -> Array:
	var path: Array = []
	var current = start
	while current != goal:
		var next = current
		if current.x < goal.x:
			next.x += 1
		elif current.x > goal.x:
			next.x -= 1
		elif current.y < goal.y:
			next.y += 1
		elif current.y > goal.y:
			next.y -= 1
		if is_cell_occupied(next):
			break
		path.append(next)
		current = next
	return path

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_unit == null:
			return
		var map: TileMapLayer = $TileMapContainer/TileMap_Dirt
		var highlight: TileMapLayer = $TileMapContainer/TileMap_Highlight
		var mouse_pos = get_global_mouse_position()
		var clicked_cell = map.local_to_map(mouse_pos)
		if highlight.get_cell_source_id(clicked_cell) != -1:
			var path = make_path(map.local_to_map(selected_unit.global_position), clicked_cell)
			selected_unit.set_path(path, map)
			highlight.clear()
