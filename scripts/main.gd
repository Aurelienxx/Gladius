extends Node2D

var map_node: Map
var units: Array = []
var selected_unit = null
var highlight_nodes: Array = []

func _ready():
	# Instanciation de la map
	map_node = Map.new()
	add_child(map_node)

	# Instanciation des unités de test
	var infantry = Infantry.new()
	add_unit(infantry, Vector2i(5, 5))

	var tank = Tank.new()
	add_unit(tank, Vector2i(10, 10))

# Fonction permettant d'ajouter des unités sur le terrain
func add_unit(unit: Unites, grid_pos: Vector2i) -> void:
	units.append(unit)
	add_child(unit)
	unit.sprite.centered = false
	unit.set_on_grid(grid_pos, map_node.cell_width, map_node.cell_height)



func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		# Récupere la position dans la grille de la souris 
		var grid_pos = get_grid_position(mouse_pos)

		var unit = get_unit_at(grid_pos)
		if unit:
			select_unit(unit)
			return

		if selected_unit != null:
			try_move_selected_unit(grid_pos)

# Fonction de selection d'une unité
func select_unit(unit):
	clear_highlights()
	selected_unit = unit
	var move_range = selected_unit.move_range
	
	# Calculer la portée avec le terrain
	var reachable = get_reachable_positions(selected_unit.grid_pos, move_range)
	highlight_positions(reachable)

func try_move_selected_unit(target_pos: Vector2i):
	var reachable = get_reachable_positions(selected_unit.grid_pos, selected_unit.move_range)
	if target_pos in reachable and get_unit_at(target_pos) == null:
		selected_unit.set_on_grid(target_pos, map_node.cell_width, map_node.cell_height)
		print("Unité déplacée à ", target_pos)
		clear_highlights()
		selected_unit = null
	else:
		print("Déplacement impossible (hors portée ou case occupée)")

func get_grid_position(mouse_pos: Vector2) -> Vector2i:
	return Vector2i(int(mouse_pos.x / map_node.cell_width), int(mouse_pos.y / map_node.cell_height))


func get_unit_at(grid_pos: Vector2i):
	for unit in units:
		if unit.grid_pos == grid_pos:
			return unit
	return null

# Affichage d'un marqueur visuel des déplacements possible
func highlight_positions(positions: Array):
	for pos in positions:
		var rect = ColorRect.new()
		rect.color = Color(0, 1, 0, 0.3)
		rect.position = Vector2(pos.x * map_node.cell_width, pos.y * map_node.cell_height)
		rect.size = Vector2(map_node.cell_width, map_node.cell_height)
		add_child(rect)
		highlight_nodes.append(rect)

# Fonction de suppression du marqueur visuel
func clear_highlights():
	for h in highlight_nodes:
		h.queue_free()
	highlight_nodes.clear()

func get_reachable_positions(start_pos: Vector2i, base_range: int) -> Array:
	var positions = []
	for y in range(map_node.ARRAY_HEIGHT):
		for x in range(map_node.ARRAY_LONG):
			var pos = Vector2i(x, y)
			var terrain_modifier = map_node.get_terrain_modifier(pos)
			# Barb_wire = 0 => infranchissable
			if terrain_modifier <= 0:
				continue
			var allowed_range = int(base_range * terrain_modifier)
			var distance = abs(pos.x - start_pos.x) + abs(pos.y - start_pos.y)
			if distance <= allowed_range:
				positions.append(pos)
	return positions
