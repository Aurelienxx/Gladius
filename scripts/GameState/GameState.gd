extends Node

var all_units: Array = []
var AIUnits: Array = []
var all_buildings: Array = []
var all_entities: Array = []

var MAX_PLAYER = 2
var current_player:int = 0 # initialisation a 0 -> c'est le tour a personne de jouer 

func next_player() -> void:
	current_player = (current_player % MAX_PLAYER) + 1
	GlobalSignal.new_player_turn.emit(current_player)

func register_unit(unit):
	if unit not in all_units:
		if unit.isAI == true:
			AIUnits.append(unit)
		all_units.append(unit)
		all_entities.append(unit)

func unregister_unit(unit):
	all_units.erase(unit)
	all_entities.erase(unit)
	unit.queue_free()
	GlobalSignal.unitDied.emit(unit)

func register_building(building):
	if building not in all_buildings:
		all_buildings.append(building)
		all_entities.append(building)

func unregister_building(building):
	all_buildings.erase(building)
	all_entities.erase(building)
	building.queue_free()

func capture_building(building):
	if building.buildingName == "QG":
		GlobalSignal.hq_Destroyed.emit()
	else: 
		# lance la capture du batiment si ce n'est pas un QG
		building.capture()

func reset():
	all_entities.clear()
	AIUnits.clear()
	all_units.clear()
	all_buildings.clear()
	current_player = 0
