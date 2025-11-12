extends Node
class_name PurchaseAI

@export var main: Node
@export var playerUnit: Node 
@export var equipe_ia: int = 2
@export var argent: int

# Caractéristiques des unités disponibles
var unit_types = {
	"Infanterie": {"cost": 15, "damage": 30, "hp": 85},
	"Camion": {"cost": 60, "damage": 30, "hp": 150},
	"Tank": {"cost": 150, "damage": 80, "hp": 400},
	"Artillerie": {"cost": 90, "damage": 75, "hp": 300}
}

func _ready():
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)

func _on_new_player_turn(player: int) -> void:
	if player != equipe_ia:
		return

	var tab = EconomyManager._get_team_tab()
	argent = tab["current_money"]
	
	await get_tree().process_frame
	_analyser_et_acheter()

func _analyser_et_acheter():
	"""
	L’IA analyse la situation et achète un nombre d’unités adapté :
	- En cas de menace forte (beaucoup d'unités ennemis) → renforce fortement
	- En cas d’infériorité numérique → produit plusieurs unités légères
	- Si équilibre → ajuste avec 1-2 unités de soutien
	"""

	# --- Analyse du terrain ---
	var allies = []
	var enemies = []

	for unit in GameState.all_units:
		if unit.equipe == equipe_ia:
			allies.append(unit)
		elif unit.equipe != 0:
			enemies.append(unit)

	















"""	for u in achats:
		if argent < unit_types[u]["cost"]:
			continue

		var instance = null
		match u:
			"Tank": instance = playerUnit.unit_tank.instantiate()
			"Infanterie": instance = playerUnit.unit_infantry.instantiate()
			"Camion": instance = playerUnit.unit_truck.instantiate()
			"Artillerie": instance = playerUnit.unit_artillery.instantiate()

		if instance:
			main.spawnUnit(instance)
			argent -= unit_types[u]["cost"]
			print("IA achète :", u, "(reste :", argent, ")")

	if achats.size() == 0:
		print("IA : Aucun achat effectué ce tour.")"""
