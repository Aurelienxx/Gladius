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
	elle sélectionne ses unités d’artillerie et exécute leurs décisions.
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
	for unit in controled_units:
		var target_cell=null
		var move = unit.get_node("MovementManager")
		var unit_pos = tilemap.get_position_on_map(unit.global_position)
		var cell = tilemap.get_reachable_cells(tilemap.MAP, unit_pos, unit.move_range)
		var close_ennemi=get_close_ennemy(unit)
		if cell.is_empty():
			continue
		if close_ennemi !=null:
			var ennemi_pos=tilemap.get_position_on_map(close_ennemi.global_position)
			target_cell=get_closed_target_cell(cell,ennemi_pos)
		else:
			target_cell = cell.pick_random()
		
		if target_cell != null:
			var path = tilemap.make_path(unit, target_cell, unit.move_range)
			move.set_path(path)
			
			# Attente d'une seconde avant de passer à l'unité suivante
			await get_tree().create_timer(1.0).timeout
			
			
	
func get_enemy_target()->Array:
	
	"""
	Fonction Permettannt de recupérer tout les ennemis
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
	:param unit: (Node) Unité dont on veut trouver la cible la plus proche.
	:return: (Node) La cible ennemie la plus proche ou null si aucune trouvée.
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
	
	
func get_closed_target_cell(cells,target_pos):
	if cells.is_empty():
		return
	var closest=cells[0]
	var min_dist=closest.distance_to(target_pos)
	for cell in cells:
		var u=cell.distance_to(target_pos)
		if u<min_dist:
			closest=cell
	return closest
	

	
