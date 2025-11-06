extends Node

var controled_units: Array = []
var all_buildings: Array = GameState.all_buildings
var all_units: Array = GameState.all_units

var ASSIGNED_TEAM:int = 2

@export var tileMapManager:Node2D
@export var main:Node2D
@export var debug_visualition: Node2D

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
	debug_visualition.reset()
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

		debug_visualition.score_map[cell] = score
		
	debug_visualition.queue_redraw()
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

func _ai_logic(unit) -> void:
	var target # sert a stocker la cible 
	var danger_map:Dictionary = compute_danger_map()

	# On choisi la cible vers laquelle on doit se déplacé/se repositionner
	target = get_best_target_attack(unit)
	
	var current_cell = tileMapManager.get_position_on_map(unit.global_position)
	if current_cell in danger_map:
		get_best_cell(current_cell,unit,target)
	else: 
		ai_move_toward_target(unit,target)
	
	# On regarde encore quelle cible est la meilleur a attaquer maintenant
	target = get_best_target_attack(unit)
	
	var new_cell = tileMapManager.get_position_on_map(unit.global_position)
	var in_range = false
	for cell in tileMapManager.get_occupied_cells(target):
		if new_cell.distance_to(cell) <= unit.attack_range:
			in_range = true
			break
	
	if in_range:
		main._on_unit_attack(unit, target)
