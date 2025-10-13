extends Node

var controled_units: Array = []
var all_buildings: Array = []

var ASSIGNED_TEAM:int = 2

@export var tileMapManager:Node2D
@export var main:Node2D

#### Setup 

func _ready():
	AiSignal.register_ai_tank.connect(register_unit)
	AiSignal.unregister_ai_tank.connect(unregister_unit) 
	
	GlobalSignal.new_player_turn.connect(new_player_turn)
	
func new_player_turn(player:int) -> void:
	if player == ASSIGNED_TEAM:
		do_your_thing()

# Registration

func register_unit(unit) -> void :
	if unit not in controled_units:
		controled_units.append(unit)

func unregister_unit(unit)-> void :
	controled_units.erase(unit)

#### Core 'Gameplay'

# Decision making 

func get_closest_enemy(unit) -> Node2D:
	var closest = null
	var best_dist = INF
	var unit_cell = tileMapManager.get_position_on_map(unit.global_position)
	for enemy in tileMapManager.all_units:
		if enemy.equipe == unit.equipe:
			continue
		var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
		var dist = unit_cell.distance_to(enemy_cell)
		if dist < best_dist:
			best_dist = dist
			closest = enemy

	# Parcourt aussi les bâtiments ennemis
	for building in tileMapManager.all_buildings:
		if building.equipe == unit.equipe:
			continue
		var build_cell = tileMapManager.get_position_on_map(building.global_position)
		var dist = unit_cell.distance_to(build_cell)
		if dist < best_dist:
			best_dist = dist
			closest = building

	return closest

# 

func do_your_thing() -> void:
	for unit in controled_units:
		if not is_instance_valid(unit):
			continue

		if unit.movement and unit.attack:
			continue

		var target = get_closest_enemy(unit)
		if target == null:
			continue

		var start_cell = tileMapManager.get_position_on_map(unit.global_position)
		var target_cell = tileMapManager.get_position_on_map(target.global_position)

		var reachable = tileMapManager.get_reachable_cells(tileMapManager.MAP, start_cell, unit.move_range)

		var best_cell = start_cell
		var best_dist = start_cell.distance_to(target_cell)
		for cell in reachable:
			var dist = cell.distance_to(target_cell)
			if dist < best_dist and not tileMapManager.is_cell_occupied(cell):
				best_dist = dist
				best_cell = cell

		var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
		if path.size() > 1:
			var manager: Node = unit.get_node("MovementManager")
			manager.set_path(path)
			unit.movement = true  
			
		var new_cell = tileMapManager.get_position_on_map(unit.global_position)
		var attack_cells = tileMapManager.get_attack_cells(tileMapManager.MAP, new_cell, unit.attack_range)

		var in_range = false
		for cell in tileMapManager.get_occupied_cells(target):
			if new_cell.distance_to(cell) <= unit.attack_range:
				in_range = true
				break

		# 6️⃣ Si à portée, attaquer
		if in_range and not unit.attack:
			unit.attack = true
			main._on_unit_attack(unit,target)
