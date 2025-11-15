extends Node

@export var main: Node
@export var playerUnit: Node
@export var equipe_ia: int = 2
@export var argent: int
@export var QG = null

# --- paramètres de comportement ---
const QG_DEFEND_RADIUS = 200.0
const LOW_HEALTH_RATIO = 0.5


var unit_data := {
	"Tank": null,
	"Artillerie": null,
	"Infanterie": null,
	"Camion": null
}

var unit_weights := {
	"Tank": 5,
	"Artillerie": 4,
	"Infanterie": 2,
	"Camion": 1
}

func _ready():
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)


# ========================================
# ============= CHARGEMENT ===============
# ========================================
func _load_data():
	var tab = EconomyManager._get_team_tab()
	argent = tab["current_money"]

	for hq in GameState.all_buildings:
		if hq.buildingName == "QG" and hq.equipe == equipe_ia:
			QG = hq

	unit_data["Tank"] = playerUnit.unit_tank.instantiate()
	unit_data["Infanterie"] = playerUnit.unit_infantry.instantiate()
	unit_data["Camion"] = playerUnit.unit_truck.instantiate()
	unit_data["Artillerie"] = playerUnit.unit_artillery.instantiate()


func _free_data():
	QG = null

	for key in unit_data.keys():
		if unit_data[key] != null:
			unit_data[key].queue_free()
	unit_data.clear()


# ========================================
# ============ DÉBUT DE TOUR =============
# ========================================
func _on_new_player_turn(player: int) -> void:
	if player != equipe_ia:
		return

	_load_data()
	await get_tree().process_frame
	_ai_turn()


func _ai_turn():
	# 1. analyse globale
	var situation = evaluate_battlefield()
	print("État du plateau :", situation)

	# 2. stratégie selon situation
	match situation:
		"supériorité", "égalité":
			_try_buy_best_unit()  # système contextuel

		"infériorité":
			_try_buy_units_defensive()

		"forte infériorité":
			_try_buy_units_fast()

	_free_data()



# ========================================
# ======= ÉVALUATION DU PLATEAU ==========
# ========================================
func evaluate_battlefield() -> String:
	var ally_force = 0
	var enemy_force = 0

	for unit in GameState.all_units:
		var w = unit_weights.get(unit.name_Unite, 1)
		if unit.equipe == equipe_ia:
			ally_force += w
		else:
			enemy_force += w

	return _compare_forces(ally_force, enemy_force)


func _compare_forces(ally_force: int, enemy_force: int) -> String:
	if enemy_force == 0:
		return "supériorité"

	if ally_force == 0:
		return "forte infériorité"

	var ratio = float(ally_force) / float(enemy_force)

	if ratio >= 1.5:
		return "supériorité"
	elif ratio >= 0.9:
		return "égalité"
	elif ratio >= 0.5:
		return "infériorité"
	else:
		return "forte infériorité"



# ========================================
# =========== ACHATS SIMPLE ==============
# ========================================
func _try_buy_units_defensive():
	var order = ["Artillerie", "Tank", "Infanterie", "Camion"]
	_try_buy_units_order(order)


func _try_buy_units_fast():
	var order = ["Camion", "Infanterie", "Tank", "Artillerie"]
	_try_buy_units_order(order)


func _try_buy_units_order(order: Array):
	for unit_name in order:
		if argent >= unit_data[unit_name].cost:
			_buy_unit(unit_name)
			return



# ========================================
# ============ IA CONTEXTUELLE ===========
# ========================================

# Analyse complète du plateau
func _evaluate_needs() -> Dictionary:
	var needs = {
		"need_defense": 0.0,
		"need_capture": 0.0,
		"need_mobility": 0.0,
		"need_firepower": 0.0,
		"need_anti_art": 0.0
	}

	var ally_count = 0
	var enemy_count = 0
	var ally_infantry = 0
	var enemy_tanks = 0
	var enemy_art = 0
	var injured_allies = 0
	var enemies_near_qg = 0

	for u in GameState.all_units:
		var utype = u.name_Unite
		var is_ally = u.equipe == equipe_ia

		if is_ally:
			ally_count += 1
			if utype == "Infanterie": ally_infantry += 1

			if "health" in u and "max_health" in u and u.max_health > 0:
				if float(u.health) / u.max_health < LOW_HEALTH_RATIO:
					injured_allies += 1
		else:
			enemy_count += 1
			if utype == "Tank": enemy_tanks += 1
			if utype == "Artillerie": enemy_art += 1

			if QG and u.global_position.distance_to(QG.global_position) <= QG_DEFEND_RADIUS:
				enemies_near_qg += 1

	# --- calcul des besoins ---
	var nb_buildings = GameState.all_buildings.size()
	if nb_buildings > 0:
		needs["need_capture"] = clamp(float(nb_buildings - ally_infantry) * 0.5, 0, 2)
	needs["need_defense"] += enemies_near_qg * 1.5
	needs["need_defense"] += clamp(max(0, enemy_count - ally_count) * 0.4, 0, 3)
	needs["need_mobility"] = clamp(injured_allies * 0.6, 0, 2)
	needs["need_firepower"] = clamp(enemy_tanks + max(0, enemy_count - ally_count) * 0.3, 0, 3)
	needs["need_anti_art"] = float(enemy_art)

	return needs


# Score utilité / coût
func _score_unit_by_need(unit_name: String, needs: Dictionary) -> float:
	var util = 0.0

	match unit_name:
		"Tank":
			util += needs["need_firepower"] * 1.4
			util += needs["need_defense"]
			util -= needs["need_mobility"] * 0.4
			util -= needs["need_anti_art"] * 0.2

		"Artillerie":
			util += needs["need_anti_art"] * 1.5
			util += needs["need_firepower"]
			util += needs["need_defense"] * 0.3

		"Infanterie":
			util += needs["need_capture"] * 1.6
			util += needs["need_defense"] * 0.6
			util += needs["need_mobility"] * 0.5
			util -= needs["need_firepower"] * 0.3

		"Camion":
			util += needs["need_mobility"] * 1.6
			util += needs["need_capture"] * 0.8
			util -= needs["need_firepower"] * 0.6

	var cost = max(1.0, float(unit_data[unit_name].cost))

	var score = util / cost
	if util < 0.3:
		score *= 0.5

	return score


# Sélection intelligente d’unité
func _choose_best_unit_by_context() -> String:
	var needs = _evaluate_needs()
	var best_unit = null
	var best_score = -INF

	for u in ["Tank", "Artillerie", "Infanterie", "Camion"]:
		var cost = unit_data[u].cost
		var score = _score_unit_by_need(u, needs)

		if cost > argent:
			score -= INF

		if score > best_score:
			best_score = score
			best_unit = u

	if best_score < 0.02:
		return ""

	return best_unit



# Achat contextuel
func _try_buy_best_unit() -> bool:
	var chosen = _choose_best_unit_by_context()

	if chosen == "":
		print("IA : aucun achat pertinent → économie")
		return false

	var cost = unit_data[chosen].cost
	if argent >= cost:
		print("IA achète :", chosen, "(coût:", cost, ")")
		_buy_unit(chosen)
		return true

	print("IA : choix pertinent mais pas assez d’argent :", chosen)
	return false



# ========================================
# ============ ACHAT D’UNITÉ =============
# ========================================
func _buy_unit(unit_name: String):
	var instance = null

	match unit_name:
		"Tank": instance = playerUnit.unit_tank.instantiate()
		"Infanterie": instance = playerUnit.unit_infantry.instantiate()
		"Camion": instance = playerUnit.unit_truck.instantiate()
		"Artillerie": instance = playerUnit.unit_artillery.instantiate()

	main.spawnUnit(instance)
	argent -= instance.cost
	EconomyManager.buy_something(instance.cost)
