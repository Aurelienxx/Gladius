extends Node

var listeUnites : Array
var listeBuildings : Array
var listeArtilleries : Array

func _ready() -> void:
	GlobalSignal.unitDied.connect(refreshLists)
	GlobalSignal.unitBought.connect(refreshLists)

func refreshLists(unit, state: bool):
	listeUnites = GameState.all_units
	if (unit and state == true):
		listeArtilleries.append(unit)
	else:
		for artillerie in listeArtilleries:
			if artillerie == unit:
				listeArtilleries.erase(artillerie)
