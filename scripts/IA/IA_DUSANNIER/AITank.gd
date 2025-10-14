extends Node

var controled_units: Array = []
var all_buildings: Array = GameState.all_buildings
var all_units: Array = GameState.all_units

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

func get_best_target(unit) -> Node2D:
	var best_target: Node2D = null
	var best_score: float = -INF

	var unit_cell = tileMapManager.get_position_on_map(unit.global_position)
	var potential_targets = tileMapManager.all_units + tileMapManager.all_buildings

	for target in potential_targets:
		if target.equipe == unit.equipe:
			continue

		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		var dist = unit_cell.distance_to(target_cell)
		var score: float = 0.0

		score -= dist * 1.0

		if target.max_hp > 0:
			var hp_ratio = float(target.current_hp) / float(target.max_hp)
			score += (1.0 - hp_ratio) * 3.0

		if target in all_units:
			match target.name_Unite:
				"Tank":
					score += 5.0
				"Infanterie":
					score += 1.0
				"Artillerie":
					score += 10.0
				"Camion":
					score += 2.0

		if target in all_buildings:
			match target.buildingName:
				"QG":
					score += 20.0
				"town":
					score += 10.0

		if dist <= unit.attack_range:
			score += 150.0

		if score > best_score:
			best_score = score
			best_target = target

	return best_target


func do_your_thing() -> void:
	for unit in controled_units:
		if not is_instance_valid(unit):
			continue

		if unit.movement and unit.attack:
			continue

		var target = get_best_target(unit)
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
		var in_range = false

		for cell in tileMapManager.get_occupied_cells(target):
			if new_cell.distance_to(cell) <= unit.attack_range:
				in_range = true
				break

		if in_range and not unit.attack:
			unit.attack = true
			main._on_unit_attack(unit, target)
