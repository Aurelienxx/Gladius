extends Node

var all_units: Array = []
var AIUnits: Array = []
var all_buildings: Array = []
var all_entities: Array = []

var MAX_PLAYER = 2
var current_player:int = 0 # initialisation a 0 -> c'est le tour a personne de jouer


#####
# Gestions des infos des joueurs 

var playerInfos: Array
var playerInfo = {
	"isAI": false
}

func _ready():
	for i in range (MAX_PLAYER):
		playerInfos.append(playerInfo.duplicate(true))

func switch_player_to_ai(index:int) -> void:
	"""
		Le joueur dont on passe l'index en parametre sera considéré comme étant une IA 
		pour le joueur 1, on donne l'index 1
	"""
	var switch_player = playerInfos.get(index-1)
	if switch_player:
		switch_player["isAI"] = true
	else:
		print("Tentative de modification d'info joueur sur un joueur inexistant")

func is_player_ai(index:int) -> bool:
	"""
		Renvoie si oui on non le joueur dont on passe l'index est une IA 
		est une IA = true
		pour le joueur 1, on donne l'index 1
	"""
	var player_info = playerInfos.get(index-1)
	if player_info:
		return player_info["isAI"]
	else:
		print("Tentative de récupération d'info joueur sur un joueur inexistant")
		return false
	
#####

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

func try_ending_turn() -> bool:
	"""
		Fonction pour passer au tour suivant, elles opéres les vérifications necessaire pour vérifié 
		si on est autorisé ou non a terminé de joué.
	"""
	GlobalSignal.pass_turn.emit()
	return true

func capture_building(building):
	if building.buildingName == "QG":
		GlobalSignal.hq_Destroyed.emit()
	else: 
		# lance la capture du batiment si ce n'est pas un QG
		building.capture(null)

func reset():
	all_entities.clear()
	AIUnits.clear()
	all_units.clear()
	all_buildings.clear()
	current_player = 0
