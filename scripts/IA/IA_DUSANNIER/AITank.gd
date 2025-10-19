extends Node

var controled_units: Array = []
var all_buildings: Array = GameState.all_buildings
var all_units: Array = GameState.all_units

var ASSIGNED_TEAM:int = 2

@export var tileMapManager:Node2D
@export var main:Node2D
@export var debug_visualition: Node2D

# Mémoire des dernières positions (évite les boucles)
var last_positions: Dictionary = {}

#### Setup 

func _ready():
	AiSignal.register_ai_tank.connect(register_unit)
	AiSignal.unregister_ai_tank.connect(unregister_unit) 
	GlobalSignal.new_turn.connect(new_player_turn)

func new_player_turn() -> void:
	if GameState.current_player == ASSIGNED_TEAM:
		do_your_thing()

# Registration

func register_unit(unit) -> void:
	if unit not in controled_units:
		controled_units.append(unit)

func unregister_unit(unit) -> void:
	controled_units.erase(unit)

#### CORE GAMEPLAY 

# Carte du danger : plus la valeur est haute, plus la zone est risquée
func compute_danger_map() -> Dictionary:
	var danger_map = {}
	for enemy in all_units:
		if enemy.equipe != ASSIGNED_TEAM:
			
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			var range_cells = tileMapManager.get_reachable_cells(enemy_cell, enemy.attack_range)
			
			var danger_score = 1
			match enemy.name_Unite:
				"Tank":
					danger_score = 4
				"Infanterie":
					danger_score = 1
				"Artillerie":
					danger_score = 0
				"Camion":
					danger_score = 2
			
			for cell in range_cells:
				danger_map[cell] = danger_map.get(cell, 0) + danger_score
				
	return danger_map


# Renvoie true si l’unité est dans une zone dangereuse
func is_in_danger(unit: Node2D, danger_map: Dictionary) -> bool:
	var cell = tileMapManager.get_position_on_map(unit.global_position)
	return danger_map.get(cell, 0) > 1


# Mémorise les dernières positions pour éviter les boucles
func remember_position(unit: Node2D):
	var cell = tileMapManager.get_position_on_map(unit.global_position)
	if not last_positions.has(unit):
		last_positions[unit] = []
	last_positions[unit].append(cell)
	if last_positions[unit].size() > 3:
		last_positions[unit].pop_front()


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
			score += 5.0

		# Bonus si entouré d'alliés
		var allies_near = get_allies_in_range(unit, 4)
		score += allies_near.size() * 1.5

		# Si le tank est blessé, il devient plus prudent
		if float(unit.current_hp) / float(unit.max_hp) < 0.4:
			score -= 20.0

		if score > best_score:
			best_score = score
			best_target = target

	return best_target


func get_allies_in_range(unit, range:int) -> Array:
	var allies = []
	var unit_cell = tileMapManager.get_position_on_map(unit.global_position)
	for ally in controled_units:
		if ally == unit:
			continue
		var ally_cell = tileMapManager.get_position_on_map(ally.global_position)
		if unit_cell.distance_to(ally_cell) <= range:
			allies.append(ally)
	return allies

func do_your_thing() -> void:
	debug_visualition.reset()
	var danger_map = compute_danger_map()

	for unit in controled_units:
		remember_position(unit)
		var target = get_best_target(unit)
		if target == null:
			continue

		var start_cell = tileMapManager.get_position_on_map(unit.global_position)
		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		var reachable = tileMapManager.get_reachable_cells(start_cell, unit.move_range)

		reachable.append(start_cell)

		var target_attack_zone = tileMapManager.get_attack_cells(target_cell, target.attack_range)

		var best_cell = start_cell
		var best_score = -INF

		for cell in reachable:
			if tileMapManager.is_cell_occupied(cell):
				continue

			var dist_to_target = cell.distance_to(target_cell)
			var danger = danger_map.get(cell, 0)
			var in_enemy_attack_zone = cell in target_attack_zone
			var can_attack_target = dist_to_target <= unit.attack_range
			var score = 0.0

			if in_enemy_attack_zone:
				score -= 30.0

			if can_attack_target and not in_enemy_attack_zone:
				score += 50.0

			score -= dist_to_target * 1.5
			score -= danger * 3.0

			if cell == start_cell:
				score += 10.0

			if score > best_score:
				best_score = score
				best_cell = cell

			debug_visualition.score_map[cell] = score

		# Déplacement
		var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
		var manager: Node = unit.get_node("MovementManager")
		manager.set_path(path)
		unit.movement = true

		# Attaque si la cible est à portée
		var new_cell = tileMapManager.get_position_on_map(unit.global_position)
		var in_range = false
		for cell in tileMapManager.get_occupied_cells(target):
			if new_cell.distance_to(cell) <= unit.attack_range:
				in_range = true
				break

		if in_range and not unit.attack:
			unit.attack = true
			main._on_unit_attack(unit, target)

		debug_visualition.queue_redraw()
