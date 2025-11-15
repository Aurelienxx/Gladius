extends Node
# Intelligence Artificielle de l'unité d'artillerie pour l'équipe 1 (bleue)
@export var tileMapManager : Node
@export var Main : Node2D

var listeEntities : Array = GameState.all_entities
var listeUnitesEnnemies : Array
var unitsValues : Dictionary

# Renvoie le bâtiment ennemi le plus proche
func closestBuilding(unit):
	var unitPos = tileMapManager.get_position_on_map(unit.global_position)
	var buildingTarget
	var dist = 0
	var smallestDistance = INF
	for entity in GameState.all_buildings:
		if entity.getTeam() != 1:
			var entityPos = tileMapManager.get_position_on_map(entity.global_position)
			dist = unitPos.distance_to(entityPos)
			if (dist <= smallestDistance):
				smallestDistance = dist
				buildingTarget = entity
	return buildingTarget

# Renvoie un tableau avec les entités qui sont en range d'attaque de l'unité courante.
func entitiesThatAreInRange(unit):
	var entitiesInRange: Array
	var unitPos = tileMapManager.get_position_on_map(unit.global_position)
	for entity in GameState.all_entities:
		if entity.getTeam() != unit.getTeam():
			var entityPos = tileMapManager.get_position_on_map(entity.global_position)
			if entity.is_in_group("units"):
				if unitPos.distance_to(entityPos) <= unit.getAttackRange():
					entitiesInRange.append(entity)
			elif entity.is_in_group("buildings"):
				var positions = tileMapManager.get_occupied_cells(entity)
				for position in positions:
					if unitPos.distance_to(position) <= unit.getAttackRange():
						entitiesInRange.append(entity)
	return entitiesInRange

# Renvoie le tableau de valeurs des entités après modification si nécessaire
func valueForEntities():
	unitsValues = {
		"Artillerie" : 50,
		"Camion" : 40,
		"Infanterie" : 30,
		"Tank" : 20
	}
	for unite in GameState.all_units:
		if unite.getTeam != 1:
			if unite.getHealth() < 75:
				unitsValues[unite.getName()] =+ 100
	return unitsValues

# Renvoie l'entité la plus proche.
func closestEntityDistance(unit, closeUnitsList):
	var dist = 0
	var smallestDistance = INF
	var closestEntity
	for entity in closeUnitsList:
		dist = tileMapManager.distance(unit, entity)
		if (dist <= smallestDistance):
			smallestDistance = dist
			closestEntity = entity
	return closestEntity

# Retourne la valeur de danger d'une case par rapport aux ennemies qui peuvent l'entourer et sa position
# sur la carte (une case proche des bords de la carte est considérée comme plus safe).
func getDangerValue(cell, enemies):
	var danger = 0.0
	for enemy in enemies:
		var enemyCell = tileMapManager.get_position_on_map(enemy.global_position)
		var dist = cell.distance_to(enemyCell)
		if dist < 3:
			danger += (5 - dist) * 3
	var mapSize = tileMapManager.MAP.get_used_rect().size
	var edgeDistance = min(cell.x, cell.y, mapSize.x - cell.x, mapSize.y - cell.y)
	danger += edgeDistance * 1.5
	return danger

# Retourne une moyenne de valeur de danger d'une grande zone (autour d'un bâtiment)
func getAreaDanger(center, enemies, radius) -> float:
	var total_danger := 0.0
	var cell_count := 0
	for x_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			var cell = center + Vector2i(x_offset, y_offset)
			if tileMapManager.MAP.get_cell_source_id(cell) == -1:
				continue
			total_danger += getDangerValue(cell, enemies)
			cell_count += 1
	if cell_count == 0:
		return 0.0
	return total_danger / cell_count

# Retourne le meilleur bâtiment vers lequel se diriger en fonction de sa distance à l'unité et de la valeur de
# danger de la zone de 3 cases qui l'entours
func bestGoal(unit):
	var safestBuilding = null
	var lowestScore = INF
	
	var unitPos = tileMapManager.get_position_on_map(unit.global_position)
	
	var enemies:Array = []
	for potential_enemie in GameState.all_units:
		if potential_enemie.equipe != unit.equipe:
			enemies.append(potential_enemie)

	for building in GameState.all_buildings:
		if building.getTeam() != 1:
			var buildingCells = tileMapManager.get_occupied_cells(building)
			var minDist = INF
			for cell in buildingCells:
				var cellPos = tileMapManager.get_position_on_map(cell.global_position) 
				var d = unitPos.distance_to(cellPos)
				if d < minDist:
					minDist = d
			var dangerScore = getAreaDanger(tileMapManager.get_position_on_map(building.global_position), enemies, 3)

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
	var unitPos = tileMapManager.get_position_on_map(unit.global_position)
	var targetPos = tileMapManager.get_position_on_map(targetBuilding.global_position)
	var everyTarget = tileMapManager.get_occupied_cells(targetBuilding) # Liste des cellules autour de targetPos

	var in_range = false
	for cell in everyTarget:
		if unitPos.distance_to(cell) <= unit.attack_range:
			in_range = true
			break

	if in_range:
		Main.attack_unit = unit
		Main.try_attacking(targetBuilding)
	
	var path = tileMapManager.get_valid_path(unit, targetPos) # Récupere le chemin entre l'unité et la cible avec A*
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

	var entitiesInRange = entitiesThatAreInRange(unit)
	if entitiesInRange.size() > 0:
		var unitsValuesDict = valueForEntities()
		var bestValue = -INF
		var target : Node = null
		for entity in entitiesInRange:
			var val = unitsValuesDict.get(entity.getName(), 0)
			if val > bestValue:
				bestValue = val
				target = entity

		if target != null:
			Main.attack_unit = unit
			Main.try_attacking(target)
