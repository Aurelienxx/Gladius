extends Node2D

var selected_unit: CharacterBody2D
var all_units: Array = []

var attack_unit: CharacterBody2D = null 
var mode: String = ""

var terrain_costs = {
	"TileMap_Dirt": 2,   # boue : coût double (50% de vitesse)
	"TileMap_Grass": 1,  # herbe : coût normal
}

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
		var reachable_cells = get_reachable_cells(map, start_cell, unit.move_range)
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

	
func get_reachable_cells(map: TileMapLayer, start: Vector2i, max_range: int) -> Array:
	var cells = []
	var open_cells = [{ "pos": start, "cost": 0 }]
	
	while open_cells.size() > 0:
		var current = open_cells.pop_front()
		var current_pos = current["pos"]
		var current_cost = current["cost"]

		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next_cell = current_pos + offset

			# Vérifie que la cellule est bien sur un Tile du terrain (pas vide, pas hors map)
			if map.get_cell_source_id(next_cell) == -1:
				continue

			# Vérifie qu'il n'y a pas déjà une unité
			if is_cell_occupied(next_cell):
				continue

			# Récupère le type de terrain et applique son coût
			var terrain = get_terrain_at_cell(next_cell)
			var terrain_multiplier = terrain_costs.get(terrain, 1)
			
			var new_cost = current_cost + terrain_multiplier
			if new_cost <= max_range and not cells.has(next_cell):
				cells.append(next_cell)
				open_cells.append({ "pos": next_cell, "cost": new_cost })
	
	return cells

func get_terrain_at_cell(cell: Vector2i) -> String:
	var dirt_map = $TileMapContainer/TileMap_Dirt
	var grass_map = $TileMapContainer/TileMap_Grass

	if grass_map.get_cell_source_id(cell) != -1:
		return "TileMap_Grass"
	elif dirt_map.get_cell_source_id(cell) != -1:
		return "TileMap_Dirt"
	return "Unknown"


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
		if is_cell_occupied(next) or $TileMapContainer/TileMap_Dirt.get_cell_source_id(next) == -1:
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
			if not is_cell_occupied(clicked_cell):
				var path = make_path(map.local_to_map(selected_unit.global_position), clicked_cell)
				var manager: Node = selected_unit.get_node("MovementManager")
				manager.set_path(path, map)
				highlight.clear()
