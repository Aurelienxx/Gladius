extends Node

var listeUnites : Array = GameState.all_units
var listeBuildings : Array
var listeArtilleries : Array
var listeUnitesEnnemies : Array
var listePosEnnemies : Array

func _ready() -> void:
	GlobalSignal.unitDied.connect(refreshLists)
	GlobalSignal.unitBought.connect(refreshLists)
	GlobalSignal.new_turn.connect(closestEntityDistance)

func refreshLists(unit, state: bool):
	for unite in listeUnites:
		if unite.equipe != GameState.current_player:
			listeUnitesEnnemies.append(unite)
	if (state == true):
		if (unit.name_Unite == "Artillerie"):
			listeArtilleries.append(unit)
	elif (state == false):
		for artillerie in listeArtilleries:
			if artillerie == unit:
				listeArtilleries.erase(artillerie)

func distance(pos1 : Vector2i, pos2 : Vector2i):
	return sqrt((pos2.x - pos1.x)**2 + (pos2.y - pos1.y)**2)

func closestEntityDistance(pos: Vector2i):
	var dist = 0
	var smallestDistance = null
	var closestEntity
	for unite in listeUnitesEnnemies:
		if smallestDistance:
			dist = distance(pos, unite.global_position)
			if (distance <= smallestDistance):
				smallestDistance = distance
				closestEntity = unite
		else:
			smallestDistance = distance(pos, unite.global_position)
	return closestEntity
