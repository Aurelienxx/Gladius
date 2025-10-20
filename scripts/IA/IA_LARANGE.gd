extends Node

@export var map : Node
@export var main : Node

func _ready() -> void:
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)

func _on_new_player_turn(player : int) -> void:
	for unit in GameState.all_units:
		if unit.equipe == GameState.current_player:
			unit.movement = false
			unit.attack = false
	if GameState.current_player == 2:
		IA_turn()

func IA_turn() -> void:
	var all_units = GameState.all_units
	
	for unit in all_units:
		if unit.equipe == GameState.current_player and not unit.movement and unit.name_Unite == "Infanterie":
			var move = unit.get_node("MovementManager")
			var unit_pos = map.get_position_on_map(unit.global_position)
			
			var target_cell = null
			var ally_nearby = get_closest_ally_nearby(unit)
			var nearby_target = get_best_enemy_nearby(unit)
			var closest_building = get_closest_building(unit,false,true)
			
			if await try_attacking_here(unit):
				continue
				
			map.display_movement(unit)
			await get_tree().create_timer(0.5).timeout
			var cells = map.get_reachable_cells(map.MAP, unit_pos, unit.move_range)
			if cells.is_empty():
				continue
				
			elif nearby_target != null :
				var target_pos = map.get_position_on_map(nearby_target.global_position)
				target_cell = get_closest_cell_to_target(cells, target_pos)
				
			elif ally_nearby != null:
				var ally_pos = map.get_position_on_map(ally_nearby.global_position)
				target_cell = get_closest_cell_to_target(cells, ally_pos)
				
			elif closest_building != null:
				var building_cell = get_closest_building_cell(unit, closest_building)
				if building_cell != null:
					target_cell = get_closest_cell_to_target(cells, building_cell)
					
			elif closest_building == null:
				closest_building = get_closest_building(unit, true, false)
				if closest_building != null:
					var building_cell = get_closest_building_cell(unit, closest_building)
					if building_cell != null:
						target_cell = get_closest_cell_to_target(cells, building_cell)

			elif target_cell == null:
				target_cell = cells.pick_random()

			if target_cell != null:
				var path = map.find_path_a_star(unit_pos, target_cell)

				path = map.make_path(unit,target_cell,unit.move_range)

				move.set_path(path)
				unit.movement = true
				map.highlight_reset()

				await get_tree().create_timer(1).timeout
				try_attacking_here(unit)

func dist(obj1, obj2):
	return obj1.global_position.distance_to(obj2.global_position)

func compare_by_distance(a, b, unit):
	return dist(unit, a) < dist(unit, b)

func get_enemy_targets():
	var targets = []
	
	for unit in GameState.all_units:
		if unit.equipe != GameState.current_player:
			targets.append(unit)
			
	for building in GameState.all_buildings:
		if building.equipe != 0 and building.equipe != GameState.current_player:
			targets.append(building)
			
	return targets


func get_target_in_attack_range(unit):
	var targets = get_enemy_targets()
	var unit_pos = map.get_position_on_map(unit.global_position)
	var enemy_target = null
	var building_target = null
	
	for target in targets:
		if target in GameState.all_units:
			var target_pos = map.get_position_on_map(target.global_position)
			if unit_pos.distance_to(target_pos) <= unit.attack_range:
				enemy_target = target
				break
		elif target in GameState.all_buildings:
			var occupied_cells = map.get_occupied_cells(target)
			for cell in occupied_cells:
				if unit_pos.distance_to(cell) <= unit.attack_range:
					building_target = target
					break
	
	if enemy_target != null:
		return enemy_target
	elif building_target != null:
		return building_target
	return null

	
func try_attacking_here(unit):
	var target = get_target_in_attack_range(unit)
	if target != null:
		map.display_attack(unit)
		await get_tree().create_timer(0.5).timeout
		main._on_unit_attack(unit, target)
		unit.movement = true
		unit.attack = true
		map.highlight_reset()
		await get_tree().create_timer(0.5).timeout
		return true
	return false


func get_ally_units():
	var allies = []
	for unit in GameState.all_units:
		if unit.equipe == GameState.current_player and unit != null:
			allies.append(unit)
	return allies

func get_closest_ally_nearby(unit):
	var allies = get_ally_units()
	if allies.is_empty():
		return null

	var proximity_range = unit.move_range * 2

	var closest = null
	var min_dist = INF
	for ally in allies:
		if ally == unit:
			continue
		var d = dist(unit, ally)
		if d < proximity_range and d < min_dist:
			min_dist = d
			closest = ally
	return closest

func get_target_buildings(unit, include_enemy := true, include_neutral := true):
	var buildings = []
	for building in GameState.all_buildings:
		if include_neutral and building.equipe == 0:
			buildings.append(building)
		elif include_enemy and building.equipe != 0 and building.equipe != unit.equipe:
			buildings.append(building)
	return buildings

func get_closest_building(unit, include_enemy := true, include_neutral := true):
	var buildings = get_target_buildings(unit, include_enemy, include_neutral)
	if buildings.is_empty():
		return null
	buildings.sort_custom(func(a, b): return compare_by_distance(a, b, unit))
	return buildings[0]
	
func get_closest_building_cell(unit, building):
	var occupied_cells = map.get_occupied_cells(building)
	if occupied_cells.is_empty():
		return null
	
	var unit_pos = map.get_position_on_map(unit.global_position)
	var closest = occupied_cells[0]
	var min_dist = unit_pos.distance_to(closest)
	
	for cell in occupied_cells:
		var d = unit_pos.distance_to(cell)
		if d < min_dist:
			min_dist = d
			closest = cell
			
	return closest
	
func get_best_enemy_nearby(unit) :
	var targets = get_enemy_targets()
	for target in targets :
		if dist(unit,target) <= unit.move_range + unit.attack_range :
			if target.current_hp <= unit.damage :
				return target

func get_closest_cell_to_target(cells, target_pos):
	if cells.is_empty():
		return
	var closest = cells[0]
	var min_dist = closest.distance_to(target_pos)
	for cell in cells:
		var d = cell.distance_to(target_pos)
		if d < min_dist:
			min_dist = d
			closest = cell
	return closest
