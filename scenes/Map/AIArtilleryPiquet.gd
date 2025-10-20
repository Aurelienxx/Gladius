extends Node
# Intelligence Artificielle de l'unité d'artillerie pour l'équipe 1 (bleue)
var listeEntities : Array = GameState.all_entities
var listeArtilleriesAlly : Array
var listeEntitiesEnnemies : Array
var listeAIUnits : Array = GameState.AIUnits
var listePosEnnemies : Array

func _ready() -> void:
	GlobalSignal.new_turn.connect(yourTurn)
	GlobalSignal.spawnedUnit.connect(addToLists)
	GlobalSignal.unitDied.connect(removeFromList)

func addToLists(unit):
	for entity in listeEntities:
		if entity.equipe == 2:
			listeEntitiesEnnemies.append(entity)
	if (unit.name_Unite == "Artillerie" and unit.equipe == 1):
		listeArtilleriesAlly.append(unit)

func removeFromList(unit):
	for artillerie in listeArtilleriesAlly:
		if artillerie == unit:
			listeArtilleriesAlly.erase(artillerie)

func distance(pos1 : Vector2i, pos2 : Vector2i):
	return sqrt((pos2.x - pos1.x)**2 + (pos2.y - pos1.y)**2)

# Renvoie l'entité la plus proche
func closestEntityDistance(pos: Vector2i):
	var dist = 0
	var smallestDistance = null
	var closestEntity
	for entity in listeEntitiesEnnemies:
		if smallestDistance:
			dist = distance(pos, entity.global_position)
			if (dist <= smallestDistance):
				smallestDistance = distance
				closestEntity = entity
		else:
			smallestDistance = distance(pos, entity.global_position)
	return closestEntity

func yourTurn():
	if !listeArtilleriesAlly.is_empty() == false:
		for artillery in listeArtilleriesAlly:
			doYourStuff(artillery)

func doYourStuff(unit):
	var target = closestEntityDistance(unit.global_position)
	GlobalSignal.attackUnit.emit(unit, target)
