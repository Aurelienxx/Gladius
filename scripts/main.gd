extends Node2D

var selected_unit: CharacterBody2D
var all_units: Array = []
var all_buildings: Array = []

var attack_unit: CharacterBody2D = null 
var mode: String = ""

var terrain_costs = {
	"TileMap_Dirt": 2,   # boue : coût double (50% de vitesse)
	"TileMap_Grass": 1,  # herbe : coût normal
}

var actual_player = 1

func _ready():
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	GlobalSignal.Unit_Attack_Clicked.connect(_on_unit_attack)

	all_units = get_tree().get_nodes_in_group("units")
	all_buildings = get_tree().get_nodes_in_group("buildings")

	print("Unités: ", all_units)
	print("QG: ", all_buildings)


func _on_unit_clicked(unit: CharacterBody2D):
	if mode == "attack" and attack_unit != null and unit != attack_unit:
		_on_unit_attack(attack_unit, unit)
		return

	var manager: Node = unit.get_node("MovementManager")
	selected_unit = unit
	mode = "move"

	var map: TileMapLayer = $TileMapContainer/TileMap_Dirt
	var highlight: TileMapLayer = $TileMapContainer/TileMap_Highlight
	highlight.clear()
	if unit.is_in_group("units"):
		if manager.is_selected:
			if selected_unit.equipe == actual_player and selected_unit.movement == false:
				var start_cell = map.local_to_map(unit.global_position)
				var reachable_cells = get_reachable_cells(map, start_cell, unit.move_range)
				for cell in reachable_cells:
					highlight.set_cell(cell, 0, Vector2i(0,0))
				highlight.set_cells_terrain_connect(reachable_cells, 0, 0, false)


func _on_unit_attack(attacker: CharacterBody2D, target: CharacterBody2D):
	
	print (attacker, " attaque ", target)
	var map: TileMapLayer = $TileMapContainer/TileMap_Dirt

	if target == null:
		# Vérifie que l’attaquant est bien un joueur actif et qu’il n’a pas déjà attaqué
		if attacker.is_in_group("buildings"):
			return
		if attacker.equipe != actual_player or attacker.attack == true:
			return

		attack_unit = attacker
		mode = "attack"

		# Affiche la zone d’attaque
		var highlight: TileMapLayer = $TileMapContainer/TileMap_Highlight
		highlight.clear()

		var start_cell = map.local_to_map(attacker.global_position)
		var attack_cells = get_attack_cells(map, start_cell, attacker.attack_range)
		for cell in attack_cells:
			highlight.set_cell(cell, 0, Vector2i(0,0))
		highlight.set_cells_terrain_connect(attack_cells, 0, 0, false)
		return

	if target.equipe != attacker.equipe:
		var building_cells = get_occupied_cells(target)
		var attacker_cell = map.local_to_map(attacker.global_position)
		var in_range = false
		for cell in building_cells:
			if attacker_cell.distance_to(cell) <= attacker.attack_range:
				in_range = true
				break

		if in_range:
			target.current_hp -= attacker.damage
			print("%s attaque %s pour %d dégâts" % [attacker.name, target.name, attacker.damage])
			attacker.attack = true
			attacker.movement = true

			if target.current_hp <= 0:
				all_units.erase(target)
				target.queue_free()

	attack_unit = null
	mode = ""
	$TileMapContainer/TileMap_Highlight.clear()
	verify_end_turn()


func get_reachable_cells(map: TileMapLayer, start: Vector2i, max_range: int) -> Array:
	var cells = []
	var open_cells = [{ "pos": start, "cost": 0 }]
	
	while open_cells.size() > 0:
		var current = open_cells.pop_front()
		var current_pos = current["pos"]
		var current_cost = current["cost"]

		for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next_cell = current_pos + offset

			# Vérifie que la cellule est bien sur un Tile du terrain et qu'il n'y a pas déjà une unité
			if map.get_cell_source_id(next_cell) == -1 and is_cell_occupied(next_cell):
				continue

			var terrain = get_terrain_at_cell(next_cell)
			var terrain_multiplier = terrain_costs.get(terrain, 1)
			var new_cost = current_cost + terrain_multiplier
			if new_cost <= max_range and not cells.has(next_cell):
				cells.append(next_cell)
				open_cells.append({ "pos": next_cell, "cost": new_cost })
	
	return cells


func get_attack_cells(map: TileMapLayer, start: Vector2i, max_range: int) -> Array:
	var cells = []
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var cell = start + Vector2i(x, y)
			if start.distance_to(cell) <= max_range:
				if map.get_cell_source_id(cell) != -1:
					cells.append(cell)
	return cells


func get_terrain_at_cell(cell: Vector2i) -> String:
	var dirt_map = $TileMapContainer/TileMap_Dirt
	var grass_map = $TileMapContainer/TileMap_Grass

	if grass_map.get_cell_source_id(cell) != -1:
		return "TileMap_Grass"
	elif dirt_map.get_cell_source_id(cell) != -1:
		return "TileMap_Dirt"
	return "Unknown"


func get_occupied_cells(unit: CharacterBody2D) -> Array:
	var cells = []
	var map = $TileMapContainer/TileMap_Dirt
	var center_cell = map.local_to_map(unit.global_position)

	var size_x = 1
	var size_y = 1
	if "size_x" in unit:
		size_x = unit.size_x
	if "size_y" in unit:
		size_y = unit.size_y

	for x in range(size_x):
		for y in range(size_y):
			var offset = Vector2i(x - size_x / 2, y - size_y / 2)
			cells.append(center_cell + offset)

	return cells


func is_cell_occupied(cell: Vector2i) -> bool:
	for unit in all_units:
		var occupied = get_occupied_cells(unit)
		if cell in occupied:
			return true
	for unit in all_buildings:
		var occupied = get_occupied_cells(unit)
		if cell in occupied:
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
		if mode == "attack":
			return

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
				selected_unit.movement = true
				verify_end_turn()


func next_player():
	if actual_player == 1:
		actual_player = 2
		for unit in all_units:
			if unit.equipe == 2:
				unit.movement = false
				unit.attack = false
	else :
		actual_player = 1
		for unit in all_units:
			if unit.equipe == 1:
				unit.movement = false
				unit.attack = false
		
func verify_end_turn():
	for unit in all_units:
		if unit.equipe != actual_player:
			continue
		# si l'unité peut encore bouger ou attaquer, on ne change pas de tour
		if unit.movement == false or unit.attack == false:
			return
	# si on arrive ici, toutes les unités de actual_player ont fini
	next_player()
	print("C'est au tour de l'équipe : ", actual_player)



func quick_select():
	var moved = false
	for unit in all_units:
		if unit.equipe == actual_player and unit.movement == false:
			var manager: Node = unit.get_node("MovementManager")
			manager.is_selected = true
			_on_unit_clicked(unit)
			moved = true
			break 

	if not moved:
		for unit in all_units:
			if unit.equipe == actual_player and unit.attack == false:
				_on_unit_attack(unit, null)
				break

func _input(event):
	var spawn = get_node("Units/PlayerUnits")
	if event is InputEventKey:
		if event.keycode == KEY_ENTER and event.pressed:
			_on_enter_pressed()
		elif event.keycode == KEY_SPACE and event.pressed:
			_on_space_pressed()
		elif event.keycode == KEY_T and event.pressed:
			var new_unit = spawn.spawn_unit("tank",actual_player)
			add_child(new_unit)
			all_units = get_tree().get_nodes_in_group("units")
		elif event.keycode == KEY_I and event.pressed:
			var new_unit = spawn.spawn_unit("infantry",actual_player)
			add_child(new_unit)
			all_units = get_tree().get_nodes_in_group("units")



func _on_enter_pressed():
	next_player()
	
func _on_space_pressed():
	quick_select()
