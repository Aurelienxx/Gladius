extends Node
# Intelligence Artificielle de l'unité d'artillerie pour l'équipe 1 (bleue)
@export var MapManager : Node
var listeEntities : Array = GameState.all_entities
var listeArtilleriesAlly : Array
var listeEntitiesEnnemies : Array
var listeUnitesEnnemies : Array
var unitsValues : Dictionary
var entitiesInRange : Array

func _ready() -> void:
	GlobalSignal.new_turn.connect(yourTurn)
	GlobalSignal.spawnedUnit.connect(addToLists)
	GlobalSignal.unitDied.connect(removeFromList)

# Ajoute des unités aux listes lorsqu'une unité est achetée
func addToLists(unit):
	for entity in listeEntities:
		if entity.equipe != 1:
			listeEntitiesEnnemies.append(entity)
		if entity.is_in_group("units"):
			listeUnitesEnnemies.append(entity)
	if (unit.name_Unite == "Artillerie" and unit.equipe == 1):
		listeArtilleriesAlly.append(unit)
		doYourStuff(unit)

# Supprime des unités des listes quand elles meurent
func removeFromList(unit):
	for enemy in listeEntitiesEnnemies:
		if enemy == unit:
			listeEntitiesEnnemies.erase(unit)
	for enemy in listeUnitesEnnemies:
		if enemy == unit:
			listeUnitesEnnemies.erase(unit)
	for artillerie in listeArtilleriesAlly:
		if artillerie == unit:
			listeArtilleriesAlly.erase(artillerie)

# Renvoie le bâtiment ennemi le plus proche
func closestBuilding(unit):
	var buildingTarget
	var dist = 0
	var smallestDistance = INF
	for entity in listeEntitiesEnnemies:
		if entity.is_in_group("buildings") and entity.getTeam() != 1:
			dist = MapManager.distance(unit, entity)
			if (dist <= smallestDistance):
				smallestDistance = dist
				buildingTarget = entity
	return buildingTarget

# Renvoie un tableau avec les entités qui sont en range d'attaque de l'unité courante.
func entitiesThatAreInRange(unit):
	var unitPos = MapManager.get_position_on_map(unit.global_position)
	for entity in listeEntitiesEnnemies:
		var entityPos = MapManager.get_position_on_map(entity.global_position)
		if entity.is_in_group("units"):
			if MapManager.distance(unitPos, entityPos) <= unit.getAttackRange():
				entitiesInRange.append(entity)
		elif entity.is_in_group("buildings"):
			var positions = MapManager.get_occupied_cells(entity)
			for position in positions:
				if MapManager.distance(unitPos, position) <= unit.getAttackRange():
					entitiesInRange.append(entity)
	return entitiesInRange

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

# Renvoie le tableau de valeurs des entités après modification si nécessaire
func valueForEntities():
	unitsValues = {
		"Artillerie" : 50,
		"Camion" : 40,
		"Infanterie" : 30,
		"Tank" : 20
	}
	for unite in listeUnitesEnnemies:
		if unite.getHealth() < 75:
			unitsValues[unite.getName()] =+ 100
	return unitsValues

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

func bestGoal(unit, enemies):
	var safestBuilding = null
	var lowestScore = INF
	
	var unitPos = MapManager.get_position_on_map(unit.global_position)

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

# Pour chaque artillerie, appelle la fonction "doYourStuff"
func yourTurn():
	if GameState.current_player == 1:
		if listeArtilleriesAlly.is_empty() == false:
			for artillery in listeArtilleriesAlly:
				if artillery == listeArtilleriesAlly[0]:
					doYourStuff(artillery)
				else:
					await GlobalSignal.AI_finished_turn
					doYourStuff(artillery)

# Appelle toutes les fonctions qui serviront à l'IA pour jouer
func doYourStuff(unit):
	var attackRange = unit.getAttackRange()
	var targetBuilding = bestGoal(unit, listeUnitesEnnemies)
	print(targetBuilding)
	var unitPos = MapManager.get_position_on_map(unit.global_position)
	var targetPos = MapManager.get_position_on_map(targetBuilding.global_position)
	var everyTarget = MapManager.get_occupied_cells(targetBuilding) # Liste des cellules autour de targetPos
	for singleTarget in everyTarget:
		if MapManager.distance(unitPos, singleTarget) <= attackRange:
			GlobalSignal.attackUnit.emit(unit, targetBuilding)
			GlobalSignal.AI_finished_turn.emit()
			return

	var attackableCells = []
	for xOffset in range(-attackRange, attackRange + 1):
		for yOffset in range(-attackRange, attackRange + 1):
			var cell = targetPos + Vector2i(xOffset, yOffset)
			if MapManager.distance(cell, targetPos) <= attackRange:
				if MapManager.MAP.get_cell_source_id(cell) != -1 and not MapManager.isCellOccupied(cell, unit):
					attackableCells.append(cell)

	if attackableCells.size() > 0:
		var path = MapManager.find_path_a_star(unitPos, attackableCells, unit)
		if path.size() > 1:
			var manager = unit.get_node("MovementManager")
			manager.set_path(path)
			await GlobalSignal.unit_finished_moving

	entitiesInRange.clear()
	entitiesInRange = entitiesThatAreInRange(unit)
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
			GlobalSignal.attackUnit.emit(unit, target)

	GlobalSignal.AI_finished_turn.emit()
