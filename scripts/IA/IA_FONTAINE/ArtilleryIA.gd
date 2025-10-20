extends Node
class_name ArtilleryAI

var controled_units: Array = [] # Liste des unités contrôlées par l’IA
var equipe_ia: int = 2 # Numéro d’équipe de l’IA
@export var tileMapManager: Node
@export var main: Node


func _ready():
	"""
	Connecte le signal de changement de tour à la fonction de gestion du tour IA.
	"""
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)


func _on_new_player_turn(player: int):
	"""
	Exécuté à chaque début de tour. Si c’est le tour de l’équipe IA,
	elle sélectionne ses unités d’artillerie et exécute leurs décisions.

	:param player: (int) Numéro de l’équipe dont c’est le tour.
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
	Fait agir successivement chaque artillerie contrôlée par l’IA avec une pause entre chaque actions.
	"""
	for unit in controled_units:
		await _make_decision(unit)
		await get_tree().create_timer(0.3).timeout


func _has_attackable_target(unit) -> bool:
	"""
	Vérifie si une cible ennemie est à portée d’attaque de l’unité donnée.

	:param unit: (Node) L’unité d’artillerie à analyser.
	:return: (bool) True si une cible est à portée, sinon False.
	"""
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var all_targets = GameState.all_units + GameState.all_buildings

	for target in all_targets:
		if target.equipe == unit.equipe or target.equipe == 0:
			continue

		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		if start_cell.distance_to(target_cell) <= unit.attack_range:
			return true

	return false


func _make_decision(unit) -> void:
	"""
	Détermine et exécute la meilleure action possible pour une unité :
	- Attaquer si une cible est à portée
	- Se déplacer puis attaquer
	- Se déplacer vers une cible prioritaire

	:param unit: (Node) L’unité d’artillerie dont on calcule la décision.
	"""
	if unit.current_hp <= 0:
		return

	if _has_attackable_target(unit):
		_attack_target(unit)
		return

	var results = {
		"attack_only": _score_attack(unit),
		"move_then_attack": _score_move_then_attack(unit),
		"move_only": _score_move_only(unit)
	}


	var best_action = _choose_action(results)
	var chosen = results[best_action]
	print(results)
	print(chosen)

	match best_action:
		"attack_only":
			await _attack_target(unit, chosen["target"])
		"move_then_attack":
			await _move_to_target(unit, chosen["cell"])
			await get_tree().create_timer(0.1).timeout
			await _attack_target(unit, chosen["target"])
		"move_only":
			await _move_to_target(unit, chosen["cell"])


# =====================================================
# ===                 CALCULS DE SCORE              ===
# =====================================================

func _get_target_score(unit, target) -> float:
	"""
	Évalue la valeur stratégique d’une cible (ennemi ou bâtiment).
	Le score dépend du type, des points de vie et de la priorité de la cible.

	:param unit: (Node) L’unité d’artillerie qui évalue la cible.
	:param target: (Node) La cible à évaluer (unité ou bâtiment).
	:return: (float) Le score attribué à la cible.
	"""
	if "name_Unite" in target:
		var base_priority = float(_get_unit_priority(target))
		var hp_ratio = float(target.current_hp) / float(target.max_hp)
		if target.current_hp <= unit.damage:
			return base_priority + 8.0
		return base_priority * (1.5 - hp_ratio)

	elif "buildingName" in target:
			if target.equipe == 1:
				if target.buildingName == "QG":
					return 10.0
				elif target.buildingName in ["Village", "Town"]:
					return 3.0
			return 0.0

	else:
		return 0.0


func _get_unit_priority(enemy) -> int:
	"""
	Retourne la priorité de base d’une unité selon son type.

	:param enemy: (Node) L’unité ennemie à évaluer.
	:return: (int) Valeur de priorité (plus haut = plus important).
	"""
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
	"""
	Trouve la cible prioritaire la plus intéressante à attaquer
	en combinant sa valeur stratégique et sa distance.

	:param unit: (Node) L’unité d’artillerie.
	:return: (Node|Null) La cible la plus pertinente ou null si aucune.
	"""
	var best_target = null
	var best_score = -INF
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)

	for enemy in GameState.all_units:
		if enemy.equipe != unit.equipe :
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			var dist = start_cell.distance_to(enemy_cell)
			var score = _get_target_score(unit, enemy) - dist * 0.5
			if score > best_score:
				best_score = score
				best_target = enemy

	for building in GameState.all_buildings:
		if building.equipe == 1:
			var building_cell = tileMapManager.get_position_on_map(building.global_position)
			var dist = start_cell.distance_to(building_cell)
			var score = _get_target_score(unit, building) - dist * 0.3
			if score > best_score:
				best_score = score
				best_target = building

	return best_target


func _score_attack(unit) -> Dictionary:
	"""
	Calcule un score si l’unité peut attaquer sans se déplacer.

	:param unit: (Node) L’unité d’artillerie.
	:return: (Dictionary) Contient le score, la cible et la cellule associée.
	"""
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var best_score := -1.0
	var best_target = null

	for target in GameState.all_units + GameState.all_buildings:
		if target.equipe == unit.equipe or target.equipe == 0:
			continue
		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		if start_cell.distance_to(target_cell) <= unit.attack_range:
			var score = _get_target_score(unit, target)
			if score > best_score:
				best_score = score
				best_target = target

	return {"score": best_score, "target": best_target, "cell": null}


func _score_move_then_attack(unit) -> Dictionary:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var best_score = -INF
	var best_target = null
	var best_cell = null

	for target in GameState.all_units + GameState.all_buildings:
		if target.equipe == unit.equipe or target.equipe == 0:
			continue

		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		var dist_to_target = start_cell.distance_to(target_cell)
		var enemy_attack_range = 0
		if "attack_range" in target:
			enemy_attack_range = target.attack_range

		# Vérifie si la cible est accessible (mouvement + portée d'attaque)
		if dist_to_target > unit.move_range + unit.attack_range:
			continue

		var path = tileMapManager.find_path_a_star(start_cell, target_cell)
		if path.size() <= 1:
			continue

		var distance_covered = 0.0

		# On teste toutes les cases atteignables dans le move_range
		for i in range(1, path.size()):
			var cell = path[i]
			var cost = tileMapManager.get_terrain_cost(cell)
			if cost < 0:
				print("Case infranchissable:", cell)
				break
			if distance_covered + cost > unit.move_range:
				break

			distance_covered += cost
			var dist = cell.distance_to(target_cell)

			print("Test cell:", cell, "dist_to_target_cell:", dist, 
				  "attack_range:", unit.attack_range, "enemy_range:", enemy_attack_range)

			# Si on peut tirer depuis cette case, et qu'on reste hors de portée ennemie
			if dist <= unit.attack_range and dist > enemy_attack_range:
				var score = _get_target_score(unit, target)
				score += (unit.attack_range - dist) * 2
				score -= distance_covered * 0.1  # légère pénalité pour long trajet

				print("=> Cell valide pour attaque:", cell, "score:", score)

				if score > best_score:
					best_score = score
					best_target = target
					best_cell = cell

	if best_score == -INF:
		print("Aucune case trouvée pour move+attack")
		return {"score": -1.0, "target": null, "cell": null}

	return {"score": best_score, "target": best_target, "cell": best_cell}





func _score_move_only(unit) -> Dictionary:
	"""
	Calcule un score si l’unité peut se déplacer.

	:param unit: (Node) L’unité d’artillerie.
	:return: (Dictionary) Contient le score, la cible et la cellule associée.
	"""
	var target = _get_priority_target(unit)
	if target == null:
		return {"score": 0.0, "target": null, "cell": null}

	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var target_cell = tileMapManager.get_position_on_map(target.global_position)

	# Calcul du chemin A* jusqu'à la cible
	var full_path = tileMapManager.find_path_a_star(start_cell, target_cell)
	if full_path.size() <= 1:
		return {"score": 0.0, "target": target, "cell": start_cell}

	# Cherche la dernière case atteignable selon move_range
	var move_distance = unit.move_range
	var distance_covered = 0
	var last_free_cell = start_cell

	for i in range(1, full_path.size()):
		var cell = full_path[i]
		var step_cost = tileMapManager.get_terrain_cost(cell)
		if step_cost < 0:
			break  # terrain infranchissable
		if distance_covered + step_cost > move_distance:
			break  # on dépasse la portée de déplacement
		distance_covered += step_cost
		last_free_cell = cell

	var score = _get_target_score(unit, target) - start_cell.distance_to(target_cell) * 0.2
	return {"score": score, "target": target, "cell": last_free_cell}


# =====================================================
# ===        CHOIX DE LA MEILLEURE ACTION          ===
# =====================================================

func _choose_action(results: Dictionary) -> String:
	"""
	Compare les scores des différentes actions possibles
	et retourne celle qui offre la meilleure option stratégique.

	:param results: (Dictionary) Résultats des évaluations d’actions.
	:return: (String) Nom de l’action choisie ("attack_only", "move_then_attack" ou "move_only").
	"""
	var best_names := []
	var best_score := -INF

	for name in results.keys():
		var s = results[name]["score"]
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
		print("pref move", best_names)
		return best_names[0]
	return "move_only"


# =====================================================
# ===              DÉPLACEMENT & ATTAQUE            ===
# =====================================================

func _move_to_target(unit, cell) -> void:
	"""
	Déplace l’unité d’artillerie vers la cellule spécifiée.
	Le chemin est calculé par le TileMapManager à partir de la position actuelle.

	:param unit: (Node) L’unité d’artillerie à déplacer.
	:param cell: (Vector2i) La cellule cible du déplacement.
	"""
	if cell == null:
		return

	var path = tileMapManager.make_path(unit, cell, unit.move_range)
	print(path)
	print(cell)
	if path.is_empty():
		return

	var manager: Node = unit.get_node("MovementManager")
	manager.set_path(path)
	await get_tree().create_timer(0.5).timeout


func _attack_target(unit, target = null) -> void:
	"""
	Effectue une attaque sur la cible la plus prioritaire à portée.
	Si aucune cible n’est précisée, la fonction choisit automatiquement la meilleure.

	:param unit: (Node) L’unité d’artillerie qui attaque.
	:param target: (Node|Null) Cible à attaquer. Si null, une cible est sélectionnée automatiquement.
	"""
	if target == null:
		var start_cell = tileMapManager.get_position_on_map(unit.global_position)
		var best_target = null
		var best_score = -INF

		for tar in GameState.all_units + GameState.all_buildings:
			if tar.equipe == unit.equipe or tar.equipe == 0:
				continue
			var target_cell = tileMapManager.get_position_on_map(tar.global_position)
			if tileMapManager.is_adjacent_cells(start_cell, target_cell, unit.attack_range):
				var score = _get_target_score(unit, tar)
				if score > best_score:
					best_score = score
					best_target = tar
		target = best_target


	if target != null:
		main._on_unit_attack(unit, target)
