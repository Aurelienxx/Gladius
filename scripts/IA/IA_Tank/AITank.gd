extends Node

var controled_units: Array = []
var all_buildings: Array = GameState.all_buildings
var all_units: Array = GameState.all_units

var ASSIGNED_TEAM:int

@export var tileMapManager:Node2D
@export var main:Node2D

###################
# Code pour équipe 1. De léothen
###################

# Score attribué a toute les entités du jeux
var entity_scoring: Dictionary = {
	"Tank"       : 2.0,
	"Infanterie" : 5.0,
	"Artillerie" : 10.0,
	"Camion"     : 7.0,
	"QG"         : 15.0,
	"Town"       : 10.0,
	"Village"    : 10.0
}

#### CORE GAMEPLAY 

# Carte du danger : plus le score est élevé, plus le danger est important
func compute_danger_map() -> Dictionary:
	"""
	Crée un dictionnaire regroupant toute les positions 'dangereuse' de la carte, en 
	leur donnant un score d'apres les dégats potentiellement reçu 
	"""
	var danger_map = {}

	for enemy in all_units:
		if enemy.equipe != ASSIGNED_TEAM:
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			
			# on augmente légérement le range de l'attack enemi pour que l'unité en se prévienne du danger
			var range = enemy.attack_range + 2 
			var range_cells = tileMapManager.get_attack_cells(enemy_cell, range)
			
			# Base du danger = 10 % des dégâts potentiels de l’unité ennemie
			var base_danger = enemy.damage * 0.1

			for cell in range_cells:
				var dist = enemy_cell.distance_to(cell)

				# Plus on est proche, plus le danger est grand
				var falloff = 1.0 - (dist / range)
				if falloff < 0:
					falloff = 0

				var danger_score = base_danger * falloff

				danger_map[cell] = danger_map.get(cell, 0.0) + danger_score

	return danger_map

func get_nearest_targets(unit_cell) -> Dictionary:
	"""
	Réalise un dictionnaire contenant la distance de toutes les entités sur le terrain vers
	chaque entités sur le terrain. A partir d'un point. 
	params:
		- unit_cell   : Vector2D
	returns:
		- dic_nearest : Dictionary
	"""
	var dict_nearest = {}
	var potential_targets = tileMapManager.all_units + tileMapManager.all_buildings
	
	for target in potential_targets:
		if target.equipe == ASSIGNED_TEAM:
			continue
		
		var target_cell = tileMapManager.get_position_on_map(target.global_position)
		var dist = unit_cell.distance_to(target_cell)
		
		dict_nearest[target] = dist
	
	return dict_nearest

# get_best_target_attack : l'unité cherche la cible la plus judicieuse à attaquer
func get_best_target_attack(unit) -> Node2D:
	"""
	Réalise l'évaluation de la meilleur unité a attacker autour de l'unité 
	"""
	var best_target: Node2D = null
	var best_score: float = -INF

	var unit_cell = tileMapManager.get_position_on_map(unit.global_position)
	
	var nearest_targets:Dictionary = get_nearest_targets(unit_cell)
	var potential_targets = nearest_targets.keys()

	for target in potential_targets:
		var score: float = 0.0
		
		# On récupére la distance entre notre unité et la target
		var dist = nearest_targets[target]
		score -= dist * 1.0
		
		# On regarde les points de vie de l'unité adverse, si elle est basse on augmente sa prioritée
		var hp_ratio = float(target.current_hp) / float(target.max_hp)
		score += (1.0 - hp_ratio) * 3.0
		
		# On ajoute le score qu'on attribut a l'unité ou le batiment 
		if target in all_units:
			score += entity_scoring[target.name_Unite]

		if target in all_buildings:
			score += entity_scoring[target.buildingName]
		
		# si on l'entité est attaquable on donne un gros bonus 
		if dist <= unit.attack_range:
			score += 10.0

		if score > best_score:
			best_score = score
			best_target = target

	return best_target
	
func get_best_cell(start_cell, unit, target):
	"""
	Permet de choisir la meilleure cellule sur laquelle se déplacé pour attaquer une unité adverse
	"""
	var danger_map = compute_danger_map()
	
	var reachable = tileMapManager.get_reachable_cells(start_cell, unit.move_range)
	reachable.append(start_cell)
	
	var target_cell = tileMapManager.get_position_on_map(target.global_position)
	
	var best_cell = start_cell
	var best_score = -INF
	
	# calcul du facteur de courage
	var hp_ratio = float(unit.current_hp) / float(unit.max_hp)
	var courage = clamp(hp_ratio * 2.0, 0.3, 1.5)
		
	for cell in reachable:
		var dist_to_target = cell.distance_to(target_cell)
		var danger = danger_map.get(cell, 0)
		var score = 0.0

		var can_attack_target: bool = dist_to_target <= unit.attack_range

		# Calcul du score influencé par le courage
		score -= danger * (1.0 / courage)  # moins de courage = plus sensible au danger

		if can_attack_target:
			score += 15.0 * courage  # plus de PV = on prend plus de risques 
			score -= dist_to_target * 0.1
		else:
			score -= dist_to_target * (1.0 / courage)

		# avance si possible 
		if not can_attack_target and dist_to_target < start_cell.distance_to(target_cell):
			score += 3.0 * courage

		# bonus si attaquer tout en étant hors de portée ennemie
		if target in all_units:
			var enemy_attack_zone = tileMapManager.get_attack_cells(target_cell, target.attack_range)
			var safe_zone = cell not in enemy_attack_zone
			if can_attack_target and safe_zone:
				score += 10.0
			elif can_attack_target and not safe_zone:
				score -= 5.0
			
		if score > best_score:
			best_score = score
			best_cell = cell

	var full_path = tileMapManager.get_valid_path(unit, best_cell)
	
	move_unit_along_path(unit, full_path)

func ai_move_toward_target(unit,target) -> void:
	"""
	Fais simplement le chemin entre l'unité et son objectif, rien de plus.
	params :
		- unit : CharacterBody2D
		- target : CharacterBody2D
	"""
	var target_cell = tileMapManager.get_position_on_map(target.global_position)

	var full_path = tileMapManager.get_valid_path(unit, target_cell)
	
	move_unit_along_path(unit, full_path)

func move_unit_random_around(unit):
	var current_cell = tileMapManager.get_position_on_map(unit.global_position)
	
	var neighbors = [
		current_cell + Vector2i(1,0), 
		current_cell + Vector2i(-1,0), 
		current_cell + Vector2i(0,1), 
		current_cell + Vector2i(0,-1)
	]

	var valid_neighbors = []

	for cell in neighbors:
		if tileMapManager.MAP.get_cell_source_id(cell) == -1:
			continue

		var terrain_cost = tileMapManager.get_terrain_cost(cell)
		if terrain_cost < 0: # obstacle
			continue

		if tileMapManager.is_cell_occupied(cell):
			continue

		var path = tileMapManager.get_valid_path(unit, cell)
		if path.size() > 1:  # si size == 1 → pas de déplacement
			valid_neighbors.append({"cell": cell, "path": path})

	if valid_neighbors.is_empty():
		return

	var choice = valid_neighbors[randi() % valid_neighbors.size()]
	var path = choice["path"]

	move_unit_along_path(unit, path)

func move_unit_along_path(unit, path) -> void:
	"""
	Déplace l'unité en utilisant un chemin donné
	params : 
		- unit : CharacterBody2D
		- path : Array[Vector2i]
	"""
	var manager: Node = unit.get_node("MovementManager")
	manager.set_path(path)
	unit.movement = true
	
#### AI decision
var ai_waiting_data := {}

func _ai_Logic_team_1(unit) -> void:
	ASSIGNED_TEAM = unit.equipe
	var danger_map:Dictionary = compute_danger_map()

	var target = get_best_target_attack(unit)
	var old_cell = tileMapManager.get_position_on_map(unit.global_position)

	ai_waiting_data[unit] = {
		"old_cell": old_cell,
		"target": target,
	}

	if old_cell in danger_map:
		get_best_cell(old_cell, unit, target)
	else:
		ai_move_toward_target(unit, target)

	GlobalSignal.unit_finished_moving.connect(_on_unit_finished_move.bind(unit), CONNECT_ONE_SHOT)

func _on_unit_finished_move(unit):
	if not ai_waiting_data.has(unit):
		return

	var data = ai_waiting_data[unit]
	var old_cell = data["old_cell"]
	var target = data["target"]

	var new_cell = tileMapManager.get_position_on_map(unit.global_position)
	var moved = new_cell != old_cell

	if not moved:
		var tcell = tileMapManager.get_position_on_map(target.global_position)
		if old_cell.distance_to(tcell) > 1:
			move_unit_random_around(unit)

	var final_cell = tileMapManager.get_position_on_map(unit.global_position)
	var best_target = get_best_target_attack(unit)

	var in_range = false
	for cell in tileMapManager.get_occupied_cells(best_target):
		if final_cell.distance_to(cell) <= unit.attack_range:
			in_range = true
			break

	if in_range:
		main.attack_unit = unit
		main.try_attacking(best_target)

	ai_waiting_data.erase(unit)


###################
# Code pour équipe 2. De Cotar
###################


func _ai_Logic_team_2(unit) -> void:
	"""
	Fonction qui permet a l'ia d'effectuer ses déplacements et attaque
	"""
	var target_cell=null
	var move = unit.get_node("MovementManager")
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	var cell = tileMapManager.get_reachable_cells(unit_pos, unit.move_range)
	var close_ennemi=get_close_ennemy(unit)
	if await attack_target(unit):
		return
	if cell.is_empty():
		return
	if close_ennemi !=null:
		var ennemi_pos=tileMapManager.get_position_on_map(close_ennemi.global_position)
		target_cell=get_closed_target_cell(unit_pos,cell,ennemi_pos)
	else:
		target_cell = cell.pick_random()
	
	if target_cell != null:
		var path = tileMapManager.make_path(unit, target_cell, unit.move_range)
		move.set_path(path)
	await get_tree().create_timer(1.0).timeout
	attack_target(unit)

	
func get_enemy_target()->Array:
	"""
	Fonction permettant de recupérer tout les ennemis
	"""
	var targets:Array=[]
	for unit in GameState.all_units:
		if unit.equipe!=GameState.current_player:
			targets.append(unit)
	for building in GameState.all_buildings:
		if building.equipe!=0 and building.equipe!=GameState.current_player:
			targets.append(building)
			
	return targets
	
	
func get_close_ennemy(unit):
	"""
	Renvoie la cible ennemie la plus proche de l'unité donnée.
	:param unit: permet de recupérer le tank.
	"""
	var targets = get_enemy_target()
	if targets.is_empty():
		return null
		
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	var closest_target = null
	var min_distance = INF
	
	for target in targets:
		var target_pos = tileMapManager.get_position_on_map(target.global_position)
		var distance = unit_pos.distance_to(target_pos)
		
		if distance < min_distance:
			min_distance = distance
			closest_target = target
			
	return closest_target
	
	
func get_closed_target_cell(unit_pos, reachable_cells, target_pos):
	"""
	cherche la cellule la plus proche de la cible 
	:param unit_pos: permet de recupérer la postion de l'unité.
	:param reachable_cells: permet de recupérer les cellule disponible.
	:param target_pos: permet de recupérer les coordonée de la cible.
	"""
	if reachable_cells.is_empty():
		return null
	var path = tileMapManager.find_path_a_star(unit_pos, target_pos)
	var best_cell = reachable_cells[0]
	var best_score = INF

	for cell in reachable_cells:
		var dist_to_target = cell.distance_to(target_pos)
		var dist_to_path = INF

		for path_cell in path:
			dist_to_path = min(dist_to_path, cell.distance_to(path_cell))

		var score = dist_to_target + dist_to_path * 0.5
		if score < best_score:
			best_score = score
			best_cell = cell

	return best_cell

func ennemy_in_range(unit):
	"""
	Renvoie les cibles ennemie dans la range.
	:param unit: permet de recupérer le tank.
	"""
	var targets = get_enemy_target()
	if targets.is_empty():
		return null
		
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	var ennemy_range = null

	for target in targets:
		var target_pos = tileMapManager.get_position_on_map(target.global_position)
		var distance = unit_pos.distance_to(target_pos)
		
		if distance < unit.attack_range:
		
			ennemy_range=target
			break
			
	return ennemy_range
	
	
func attack_target(unit):
	"""
	Attaque les ennemie ciblé.
	:param unit: permet de recupérer le tank.
	"""
	var target = ennemy_in_range(unit)
	if target!=null:
		main.attack_unit = unit
		main.try_attacking(target)
		await get_tree().create_timer(0.5).timeout
		return true
	return false



###################
# Fais jouer
###################


func play_unit(unit:CharacterBody2D)->void:
	"""
		Fais joué l'unité par rapport a l'equipe donné 
	"""
	match unit.equipe:
		1:
			_ai_Logic_team_1(unit)
		2:
			_ai_Logic_team_2(unit)
		_:
			_ai_Logic_team_1(unit)
