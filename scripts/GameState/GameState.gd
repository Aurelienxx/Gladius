extends Node

var all_units: Array = []
var all_buildings: Array = []

var MAX_PLAYER = 2
var current_player:int = 0 # initialisation a 0 -> c'est le tour a personne de jouer
var playerInfos: Array
var playerState = {
	"isAI":  false
}

func _ready():
	for i in range (MAX_PLAYER):
		playerInfos.append(playerState.duplicate(true))
	print(playerInfos)

func next_player() -> void:
	current_player = (current_player % MAX_PLAYER) + 1
	GlobalSignal.new_player_turn.emit(current_player)

func register_unit(unit):
	if unit not in all_units:
		all_units.append(unit)

func unregister_unit(unit):
	all_units.erase(unit)
	unit.queue_free()

func register_building(building):
	if building not in all_buildings:
		all_buildings.append(building)

func unregister_building(building):
	all_buildings.erase(building)
	building.queue_free()

func capture_building(building):
	if building.buildingName == "QG":
		GlobalSignal.hq_Destroyed.emit()
	else: 
		# lance la capture du batiment si ce n'est pas un QG
		building.capture()
