extends Node
# Intelligence Artificielle de l'unité d'artillerie pour l'équipe 1 (bleue)
@export var MapManager : Node
@export var Main : Node2D

var listeEntities : Array = GameState.all_entities
var listeUnitesEnnemies : Array
var unitsValues : Dictionary

# Renvoie le bâtiment ennemi le plus proche
func closestBuilding(unit):
	var buildingTarget
	var dist = 0
	var smallestDistance = INF
	for entity in GameState.all_buildings:
		if entity.getTeam() != 1:
			dist = MapManager.distance(unit, entity)
			if (dist <= smallestDistance):
				smallestDistance = dist
				buildingTarget = entity
	return buildingTarget

# Renvoie l'entité la plus proche.
func closestEntityDistance(unit, closeUnitsList):
	var dist = 0
	var smallestDistance = INF
	var closestEntity
	for entity in closeUnitsList:
		dist = MapManager.distance(unit, entity)
		if (dist <= smallestDistance):
			smallestDistance = dist
			closestEntity = entity
	return closestEntity

func getDangerValue(cell, ennemies):
	var danger = 0.0
	for enemy in ennemies:
		var enemyCell = MapManager.MAP.local_to_map(enemy.global_position)
		var dist = MapManager.distance(enemyCell, cell)
		if dist < 7:
			danger += (7 - dist) * 3
	var mapSize = MapManager.MAP.get_used_rect().size
	var edgeDistance = min(cell.x, cell.y, mapSize.x - cell.x, mapSize.y - cell.y)
	danger += edgeDistance * 2
	return danger

func getAreaDanger(center, enemies, radius) -> float:
	var total_danger := 0.0
	var cell_count := 0
	for x_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			var cell = center + Vector2i(x_offset, y_offset)
			if MapManager.MAP.get_cell_source_id(cell) == -1:
				continue
			total_danger += getDangerValue(cell, enemies)
			cell_count += 1
	if cell_count == 0:
		return 0.0
	return total_danger / cell_count

func bestGoal(unit):
	var safestBuilding = null
	var lowestScore = INF
	
	var unitPos = MapManager.get_position_on_map(unit.global_position)
	
	var enemies:Array = []
	for potential_enemie in GameState.all_units:
		if potential_enemie.equipe != unit.equipe:
			enemies.append(potential_enemie)
	

	for building in listeEntities:
		if building.is_in_group("buildings") and building.getEquipe() != 1:
			var buildingCells = MapManager.get_occupied_cells(building)
			var minDist = INF
			for cell in buildingCells:
				var d = MapManager.distance(unitPos, cell)
				if d < minDist:
					minDist = d
			var dangerScore = getAreaDanger(MapManager.get_position_on_map(building.global_position), enemies, 4)

			var score = (minDist * 1.0) + (dangerScore * 2.0)
			if dangerScore < 1.0:
				score *= 0.5
			if score < lowestScore:
				lowestScore = score
				safestBuilding = building
	return safestBuilding

# Appelle toutes les fonctions qui serviront à l'IA pour jouer
func doYourStuff(unit):
	var targetBuilding = bestGoal(unit)
	
	#print(targetBuilding)
	
	var unitPos = MapManager.get_position_on_map(unit.global_position)
	var targetPos = MapManager.get_position_on_map(targetBuilding.global_position)
	var everyTarget = MapManager.get_occupied_cells(targetBuilding) # Liste des cellules autour de targetPos
	
	var in_range = false
	for cell in everyTarget:
		if unitPos.distance_to(cell) <= unit.attack_range:
			in_range = true
			break

	if in_range:
		Main.attack_unit = unit
		Main.try_attacking(targetBuilding)
	
	var path = MapManager.get_valid_path(unit, targetPos) # Récupere le chemin entre l'unité et la cible avec A*
	if path.size() <= 1: # Le chemin est vide
		return
	
	var manager = unit.get_node("MovementManager")
	manager.set_path(path)
	
	in_range = false
	for cell in everyTarget:
		if unitPos.distance_to(cell) <= unit.attack_range:
			in_range = true
			break

	if in_range:
		Main.attack_unit = unit
		Main.try_attacking(targetBuilding)
