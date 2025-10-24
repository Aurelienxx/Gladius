extends Node
class_name ai_cotar

@export var tilemap:Node
@export var main: Node
@export var equipe_ia: int = 2


var controled_units:Array=[]
func _ready() -> void:
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)
	
func _on_new_player_turn(player: int):
	"""
	Exécuté à chaque début de tour. Si c’est le tour de l’équipe IA,
	elle sélectionne ses unités de tank et exécute leurs décisions.
	:param player: (int) Numéro de l’équipe dont c’est le tour.
	"""
	if player != equipe_ia:
		return
	controled_units.clear()
	for unit in GameState.all_units:
		if unit.equipe == player and unit.name_Unite == "Tank":
			controled_units.append(unit)
			
	await bidule()
	controled_units.clear() 
	
func bidule() -> void:
	"""
	Fonction qui permet a l'ia d'effectuer ses déplacements et attaque
	"""
	for unit in controled_units:
		var target_cell=null
		var move = unit.get_node("MovementManager")
		var unit_pos = tilemap.get_position_on_map(unit.global_position)
		var cell = tilemap.get_reachable_cells(tilemap.MAP, unit_pos, unit.move_range)
		var close_ennemi=get_close_ennemy(unit)
		if await attack_target(unit):
			continue
		if cell.is_empty():
			continue
		if close_ennemi !=null:
			var ennemi_pos=tilemap.get_position_on_map(close_ennemi.global_position)
			target_cell=get_closed_target_cell(unit_pos,cell,ennemi_pos)
		else:
			target_cell = cell.pick_random()
		
		if target_cell != null:
			var path = tilemap.make_path(unit, target_cell, unit.move_range)
			move.set_path(path)
			
		# Attente d'une seconde avant de passer à l'unité suivante
		await get_tree().create_timer(1.0).timeout
		if await attack_target(unit):
			continue
			
			
			
			
			
	
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
		
	var unit_pos = tilemap.get_position_on_map(unit.global_position)
	var closest_target = null
	var min_distance = INF
	
	for target in targets:
		var target_pos = tilemap.get_position_on_map(target.global_position)
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
	var path = tilemap.find_path_a_star(unit_pos, target_pos)
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
		
	var unit_pos = tilemap.get_position_on_map(unit.global_position)
	var ennemy_range = null

	
	for target in targets:
		var target_pos = tilemap.get_position_on_map(target.global_position)
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
		main._on_unit_attack(unit,target)
		await get_tree().create_timer(0.5).timeout
		return true
	return false
		
