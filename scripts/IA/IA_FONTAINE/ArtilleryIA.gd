extends Node
class_name ArtilleryAI

var controled_units: Array = [] # Liste des unités contrôlées par l’IA
var equipe_ia: int = 2 # Numéro d’équipe de l’IA
@export var tileMapManager: Node
@export var main: Node

func _has_attackable_target(unit) -> bool:
	"""
	Vérifie si une cible ennemie est à portée d’attaque de l’unité.
	
	:param unit: (Node) L’unité d’artillerie à analyser.
	:return: (bool) True si une cible est à portée, sinon False.
	"""
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	
	for target in GameState.all_units + GameState.all_buildings:
		if target.equipe == unit.equipe or target.equipe == 0:
			continue # Si l'unité adverse est de l'équipe IA ou équipe 0 (neutre) alors on ignore
			
		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		if start_cell.distance_to(target_cell) <= float(unit.attack_range) + 0.1:
			return true # Si l'unité adverse est à distance d'attaque on renvoie True
			
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

	# Vérifie si une attaque directe est possible
	var attack_data = _score_attack(unit)
	if attack_data["target"] != null:
		await _attack_target(unit, attack_data["target"])
		return

	# Sinon, on évalue les autres options
	var results = {
		"attack_only": attack_data,
		"move_then_attack": _score_move_then_attack(unit),
		"move_only": _score_move_only(unit)
	}

	var best_action = _choose_action(results) # Sélectionne l’action au score le plus élevé
	var chosen = results[best_action]
	
	match best_action:
		"attack_only":
			await _attack_target(unit, chosen["target"])
		"move_then_attack":
			await _move_to_target(unit, chosen["cell"])
			#await get_tree().create_timer(0.1).timeout # Pause d'une seconde entre les deux actions
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
	if "name_Unite" in target: # Si la cible est une unité
		var base_priority = float(_get_unit_priority(target))
		var hp_ratio = float(target.current_hp) / float(target.max_hp)
		var missing_hp_ratio = 1.0 - hp_ratio # Ratio de la vie perdu de la cible
		var score = base_priority * (1.5 - hp_ratio)

		score += missing_hp_ratio * 5.0 # Plus la cible est blessée, plus elle devient intéressante

		# Bonus si elle peut être éliminée en un coup
		if target.current_hp <= unit.damage:
			score += 8.0 

		return score

	elif "buildingName" in target: # Si la cible est un bâtiment ennemi
		if target.equipe == 1:
			match target.buildingName:
				"QG":
					return 10.0
				"Village", "Town":
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
			var dist = start_cell.distance_to(enemy_cell) # Evalue la distance entre l'unité et la cible
			var score = _get_target_score(unit, enemy) - dist * 0.5 # Evalue le score en fonction de son score et sa distance
			if score > best_score:
				best_score = score
				best_target = enemy

	for building in GameState.all_buildings:
		if building.equipe == 1:
			var building_cell = tileMapManager.get_position_on_map(building.global_position)
			var dist = start_cell.distance_to(building_cell) # Evalue la distance entre l'unité et le batiment ennemie
			var score = _get_target_score(unit, building) - dist * 0.3 # Evalue le score en fonction de son score et sa distance
			if score > best_score:
				best_score = score
				best_target = building

	return best_target # Retourne l'ennemeie prioritaire

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
		if start_cell.distance_to(target_cell) <= unit.attack_range: # Si la distance de la cible est inferieur à la distance d'attaque 
			var score = _get_target_score(unit, target) # On récuperer le score de l'ennemie
			if score > best_score: # Si le score de la cible est superieur au meilleur score déjà enregister 
				best_score = score # alors on le remplace
				best_target = target # On enregistre la cible en tant que la meilleur

	return {"score": best_score, "target": best_target, "cell": null}

func _score_move_then_attack(unit) -> Dictionary:
	""" 
	Calcule un score si l’unité peut attaquer après s'être déplacé. 
	L'IA cherche à attaquer en restant hors de portée ennemie et à maximiser la distance à sa cible. 
	
	:param unit: (Node) L’unité d’artillerie. 
	:return: (Dictionary) Contient le score, la cible et la cellule associée. 
	"""
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var best_score = -INF
	var best_target = null
	var best_cell = null


	for target in GameState.all_units + GameState.all_buildings:
		if target.equipe == unit.equipe or target.equipe == 0:
			continue

		var target_cell = tileMapManager.get_position_on_map(target.global_position)

		var path = tileMapManager.find_path_a_star(start_cell, target_cell) # Récupere le chemin entre l'unité et la cible avec A*
		if path.size() <= 1: # Le chemin est vide
			continue

		var distance_covered = 0.0
		for i in range(1, path.size()): # Pour chaques cases du chemin hormis la case de debut
			var cell = path[i]
			var cost = tileMapManager.get_terrain_cost(cell)
			if cost < 0:
				break
			if distance_covered + cost > unit.move_range: # Si la distance est superieur au deplacement de l'unité on passe
				break

			distance_covered += cost # Ajoute le cout de deplacement à la distance couverte
			var dist = cell.distance_to(target_cell)

			# On ne garde que les positions qui permettent d'attaquer
			if dist <= unit.attack_range:
				var score = _get_target_score(unit, target) + 10.0 * (1.0 - abs(unit.attack_range - dist)) # Cacule le score en fonction de la distanxe de l'unité 
				score -= distance_covered * 0.1
				if score > best_score: # Si le score de la cible est superieur au meilleur score déjà enregister 
					best_score = score # alors on le remplace
					best_target = target # On enregistre la cible en tant que la meilleur
					best_cell = cell # On enregistre la case en tant que la meilleur

	if best_score == -INF:
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

	for i in range(1, full_path.size()):# Pour chaques cases du chemin hormis la case de debut
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

	for name in results.keys(): # Pour chaque résultats
		var s = results[name]["score"]
		if s > best_score: # Si le score courant est surpérieur au meilleur 
			best_score = s # Remplace le meilleur score
			best_names = [name] # Remplace le nom du meilleur score
		elif is_equal_approx(s, best_score): # Si ils sont égaux 
			best_names.append(name) # Ajouter au meilleur nom

	var preference := ["attack_only", "move_then_attack", "move_only"]
	for pref in preference:
		if pref in best_names:
			return pref
	

	if best_names.size() > 0:
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
	if cell == null: # Si il n'y a pas de case alors on retourne
		return

	var path = tileMapManager.make_path(unit, cell, unit.move_range) # Créer le chemin vers la case
	if path.is_empty():
		GlobalSignal.unit_finished_moving.emit()
		return

	var manager: Node = unit.get_node("MovementManager") # Récupere de Node de deplacement de l'unité
	manager.set_path(path) # Déplace l'unité
	#await get_tree().create_timer(0.5).timeout # Pause de 5 secondes pour laisser le temps de se déplacer à l'unité

func _attack_target(unit, target = null) -> void:
	"""
	Effectue une attaque sur la cible la plus prioritaire à portée.
	Si aucune cible n’est précisée, la fonction choisit automatiquement la meilleure.

	:param unit: (Node) L’unité d’artillerie qui attaque.
	:param target: (Node|Null) Cible à attaquer. Si null, une cible est sélectionnée automatiquement.
	"""
	if target == null: # Si pas de cible alors en choisie une dans la porté d'attaque
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
		main.attack_unit = unit
		main.try_attacking(target)
