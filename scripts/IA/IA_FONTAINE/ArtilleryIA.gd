extends Node
class_name ArtilleryAI

var controled_units: Array = []
var equipe_ia: int = 2
@export var tileMapManager: Node
@export var main: Node


func _ready():
	"""
	Initialise la connexions du signal.
	"""
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)

func _on_new_player_turn(player: int):
	"""
	Fonction appelé au debut d'un tour.
	Initialise la liste des unités controllés par l'IA et appel la fonction de gestion des actions
	"""
	if player != equipe_ia:
		return

	controled_units.clear()
	for unit in GameState.all_units:
		if unit.equipe == player and unit.name_Unite == "Artillerie":
			controled_units.append(unit)

	await do_your_thing()
	controled_units.clear()


func do_your_thing() -> void:
	"""
	Fonction d'appel de la fonction de decision pour chaques unités
	Mets une pause entre chaques unités pour qu'elle ai le temps de faire ses actions
	"""
	for unit in controled_units:
		await _make_decision(unit)
		await get_tree().create_timer(0.3).timeout
	print("---------- Fin du tour ----------")


func _has_attackable_target(unit) -> bool:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	# toutes cibles : unités + bâtiments
	var all_targets = GameState.all_units + GameState.all_buildings
	for target in all_targets:
		if target.equipe == unit.equipe:
			continue
		
		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		
		# on regarde si la cible est dans notre portée
		if start_cell.distance_to(target_cell) <= unit.attack_range:
			return true
	return false


func _make_decision(unit) -> void:
	if unit.current_hp <= 0:
		return

	# Si on peut attaquer maintenant : on attaque (priorité absolue)
	if _has_attackable_target(unit):
		_attack_target(unit)
		return

	var scores = {
		"attack_only": _score_attack(unit),
		"move_then_attack": _score_move_then_attack(unit),
		"move_only": _score_move_only(unit),
	}
	var best_action = _choose_action(scores)

	match best_action:
		"attack_only":
			await _attack_target(unit)
		"move_then_attack":
			await _move_to_target(unit)
			await _attack_target(unit)
		"move_only":
			await _move_to_target(unit)


# Calcule le "score" de chaques enemies
func _get_target_score(unit, target) -> float:
	# Si c’est une unité
	if "name_Unite" in target:
		var base_priority = float(_get_unit_priority(target))
		var hp_ratio = float(target.current_hp) / float(target.max_hp)
		if target.current_hp <= unit.damage:
			return base_priority + 8.0
		return base_priority * (1.5 - hp_ratio)
	# Sinon c’est un bâtiment
	elif "buildingName" in target:
		if target.buildingName == "QG" and target.equipe != equipe_ia:
			return 10.0
		elif (target.buildingName == "Village" or target.buildingName == "Town") and target.equipe != equipe_ia:
			return 3.0
		else:
			return 0.0
	else:
		return 0.0


func _get_unit_priority(enemy) -> int:
	match enemy.name_Unite:
		"Artillerie":
			return 10
		"Camion":
			return 10
		"Tank":
			return 6
		"Infanterie":
			return 4
		_:
			return 3


func _get_priority_target(unit):
	var best_target = null
	var best_score = -INF
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)

	# Cherche toutes les unités ennemies
	for enemy in GameState.all_units:
		if enemy.equipe != unit.equipe:
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			var dist = start_cell.distance_to(enemy_cell)
			var score = _get_target_score(unit, enemy) - dist * 0.5
			if score > best_score:
				best_score = score
				best_target = enemy

	# Cherche tous les bâtiments ennemis
	for building in GameState.all_buildings:
		if building.equipe != equipe_ia:
			var building_cell = tileMapManager.get_position_on_map(building.global_position)
			var dist = start_cell.distance_to(building_cell)
			var score = _get_target_score(unit, building) - dist * 0.3
			if score > best_score:
				best_score = score
				best_target = building

	return best_target


# =====================================================
# ===                 SCORES D'ACTIONS              ===
# =====================================================

func _score_attack(unit) -> float:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var best_score := -1.0

	for enemy in GameState.all_units:
		if enemy.equipe != unit.equipe:
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			if tileMapManager.is_adjacent_cells(start_cell, enemy_cell, unit.attack_range):
				var score = _get_target_score(unit, enemy)
				if score > best_score:
					best_score = score

	for building in GameState.all_buildings:
		if building.equipe != equipe_ia or building.equipe == 1 :
			var building_cell = tileMapManager.get_position_on_map(building.global_position)
			if tileMapManager.is_adjacent_cells(start_cell, building_cell, unit.attack_range):
				var score = _get_target_score(unit, building)
				if score > best_score:
					best_score = score

	return best_score


func _score_move_then_attack(unit) -> float:
	var start = tileMapManager.get_position_on_map(unit.global_position)
	var reachable_cells = tileMapManager.get_reachable_cells(tileMapManager.MAP, start, unit.move_range)
	if reachable_cells.is_empty():
		return 0.0

	var best_score = 0.0
	for cell in reachable_cells:
		for enemy in GameState.all_units:
			if enemy.equipe != unit.equipe:
				var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
				if tileMapManager.is_adjacent_cells(cell, enemy_cell, unit.attack_range):
					var dist = cell.distance_to(enemy_cell)
					var score = _get_target_score(unit, enemy) - dist * 0.5
					if score > best_score:
						best_score = score

		for building in GameState.all_buildings:
			if building.equipe != equipe_ia:
				var building_cell = tileMapManager.get_position_on_map(building.global_position)
				if tileMapManager.is_adjacent_cells(cell, building_cell, 1):
					var dist = cell.distance_to(building_cell)
					var score = _get_target_score(unit, building) - dist * 0.3
					if score > best_score:
						best_score = score

	if best_score == 0.0:
		return -0.5
	return best_score


func _score_move_only(unit) -> float:
	var target = _get_priority_target(unit)
	if target == null:
		return 0.0

	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var target_cell = tileMapManager.get_position_on_map(target.global_position)
	var dist = start_cell.distance_to(target_cell)

	# Pondération selon le type de cible
	var distance_penalty = 0.5  # défaut pour les unités
	if "buildingName" in target:
		distance_penalty = 0.3  # pour les bâtiments, moins important

	var val = _get_target_score(unit, target) - dist * distance_penalty
	if val > 0.0:
		return val
	else:
		return 0.1



# =====================================================
# ===        CHOIX DE LA MEILLEURE ACTION          ===
# =====================================================

func _choose_action(scores: Dictionary) -> String:
	var best_names := []
	var best_score := -INF

	for name in scores.keys():
		var s = scores[name]
		if s > best_score:
			best_score = s
			best_names = [name]
		elif is_equal_approx(s, best_score):
			best_names.append(name)

	var preference := ["attack_only", "move_then_attack", "move_only"]
	for pref in preference:
		if pref in best_names:
			return pref

	if best_names.size() > 0:
		return best_names[0]
	return "move_only"


# =====================================================
# ===      DÉPLACEMENT LOGIQUE VERS LA CIBLE        ===
# =====================================================

# Déplace l'artillerie pour que la cible soit à portée d'attaque
func _move_to_target(unit) -> void:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var reachable_cells = tileMapManager.get_reachable_cells(tileMapManager.MAP, start_cell, unit.move_range)
	if reachable_cells.is_empty():
		return

	var target = _get_priority_target(unit)
	if target == null:
		print(unit.name_Unite, "ne trouve aucune cible prioritaire.")
		return

	var target_cell = tileMapManager.get_position_on_map(target.global_position)
	var desire_range = 1
	if "name_Unite" in target:
		desire_range = unit.attack_range

	# Si la cible est déjà à portée, inutile de bouger
	if tileMapManager.is_adjacent_cells(start_cell, target_cell, desire_range):
		print(unit.name_Unite, "a déjà la cible à portée -> reste en place.")
		return

	# Recherche d'une cellule idéale
	var best_cell = null
	var best_score = INF  # plus petit = mieux

	for cell in reachable_cells:
		# distance à la cible
		var dist_to_target = cell.distance_to(target_cell)
		# distance depuis la position actuelle (on préfère les déplacements courts)
		var dist_from_start = start_cell.distance_to(cell)

		# Score combiné : favorise les cellules plus proches de la cible,
		# mais accepte de bouger si cela aide à contourner un obstacle
		var score = dist_to_target + (dist_from_start * 0.3)

		if score < best_score:
			best_score = score
			best_cell = cell

	# Si pour une raison quelconque aucune cellule n'est meilleure (très rare)
	if best_cell == null:
		print(unit.name_Unite, "n’a trouvé aucune cellule de déplacement utile.")
		return

	# Calcul du chemin vers la meilleure cellule
	var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
	if path.is_empty():
		print(unit.name_Unite, "n’a pas trouvé de chemin valide.")
		return

	print(unit.name_Unite, "se déplace vers une meilleure position pour atteindre sa cible.")
	var manager: Node = unit.get_node("MovementManager")
	manager.set_path(path)
	await get_tree().create_timer(0.5).timeout




# =====================================================
# ===        ATTAQUE SI UNE CIBLE À PORTÉE          ===
# =====================================================
func _attack_target(unit) -> void:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var best_target = null
	var best_score = -INF

	# Parcours toutes les cibles possibles (unités + bâtiments)
	var all_targets = GameState.all_units + GameState.all_buildings
	for target in all_targets:
		if target.equipe == unit.equipe or target.equipe == 0:
			continue  # on ignore ses propres unités / bâtiments

		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		
		# Détermine la portée selon le type
		var attack_range = unit.attack_range

		# Vérifie si la cible est à portée
		if tileMapManager.is_adjacent_cells(start_cell, target_cell, attack_range):
			var score = _get_target_score(unit, target)
			if score > best_score:
				best_score = score
				best_target = target

	if best_target != null:
		main._on_unit_attack(unit, best_target)
