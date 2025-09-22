extends Node2D

var selected_unit: CharacterBody2D
var all_units: Array = []

var attack_unit: CharacterBody2D = null 
var mode: String = ""

func _ready():
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	GlobalSignal.Unit_Attack_Clicked.connect(_on_unit_attack)

	var player_units = $Units/PlayerUnits

	for unit in player_units.get_children():
		all_units.append(unit)


func _on_unit_clicked(unit: CharacterBody2D):
	var manager: Node = unit.get_node("MovementManager")

	# Le joueur souhaite attaquer
	if mode == "attack" and attack_unit != null and unit != attack_unit:
		_on_unit_attack(attack_unit, unit)
		return

	# Le joueur souhaite déplacer l'unité 
	selected_unit = unit
	mode = "move"

	var map: TileMapLayer = $TileMapContainer/TileMap_Dirt
	var highlight: TileMapLayer = $TileMapContainer/TileMap_Highlight
	highlight.clear()

	if manager.is_selected:
		var start_cell = map.local_to_map(unit.global_position)
		var reachable_cells = get_reachable_cells(map, start_cell, manager.move_range)
		for cell in reachable_cells:
			highlight.set_cell(cell, 0, Vector2i(1,1))
		highlight.set_cells_terrain_connect(reachable_cells, 0, 0, false)





func _on_unit_attack(attacker: CharacterBody2D, target: CharacterBody2D):
	if target == null:
		# Le joueur souhaite attaquer avec l'unité 
		attack_unit = attacker
		mode = "attack"
	else:
		# Le joueur souhaite attaquer l'unité 
		
		
		
		# Réinitialisation du système d'attaque
		attack_unit = null
		mode = ""

	
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
			var manager: Node = selected_unit.get_node("MovementManager")
			manager.set_path(path, map)
			highlight.clear()
