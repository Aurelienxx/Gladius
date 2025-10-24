extends Node

@export var tileMapManager : Node
@export var main : Node

# Valeur des unités pour l'IA
var UNIT_VALUES = {
	"Infanterie": 100,
	"Artillerie": 150,
	"Camion": 50,
	"Tank": 200,
}

func _ready():
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)
	
func _on_new_player_turn(player : int):
	for unit in GameState.all_units:
		if unit.equipe == GameState.current_player:
			unit.movement = false
	if GameState.current_player == 2:
		await IA_turn()

# --- TOUR DE L’IA ---
func IA_turn():
	var all_units = GameState.all_units
	
	for unit in all_units:
		if unit.equipe == GameState.current_player and not unit.movement and unit.name_Unite == "Camion":
			await Ai_Truck(unit)
			
# --- LOGIQUE POUR L'IA DES CAMIONS ---
func Ai_Truck(unit):
	var equipe = unit.equipe
	var all_units = GameState.all_units
	var all_buildings = GameState.all_buildings
	
	var start = tileMapManager.get_position_on_map(unit.global_position)
	var attack_cells = tileMapManager.get_attack_cells(tileMapManager.MAP, start, unit.attack_range)
	var reachable_cells = tileMapManager.get_reachable_cells(tileMapManager.MAP, start, unit.move_range + unit.attack_range)
		
	var neutral_village = find_nearest_neutral_village(unit)
	var enemy_village = find_nearest_enemy_village(unit)
	var enemy_hq = get_enemy_hq(equipe)
	
	# Recherche un village neutre à capturer
	if neutral_village != null:
		await move_to_target(unit, neutral_village.global_position)
		unit.movement = true
		
	# Sinon cherche un village ennemi à détruire
	elif enemy_village != null:
		await move_to_target(unit, enemy_village.global_position)
		unit.movement = true
		
	# Sinon déplacement vers le QG ennemi
	elif enemy_hq != null:
		await move_to_target(unit,enemy_hq.global_position)
		unit.movement = true
		
	# Recherche de l'unité à attaquer
	var best_unit = null
	var best_value = 0
	
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	for verify_unit in all_units:
		if verify_unit.equipe == equipe:
			continue
		var unit_cell = tileMapManager.get_position_on_map(verify_unit.global_position)
		if unit_pos.distance_to(unit_cell) <= unit.attack_range:
			var current_value = UNIT_VALUES.get(verify_unit.name_Unite, 0)
			if current_value > best_value:
				print(best_value)
				best_value = current_value
				best_unit = verify_unit

	if best_unit != null:
		await attack_target(unit, best_unit)
		return

	# Recherche d’un bâtiment à portée d’attaque
	for building in all_buildings:
		print("oui")
		if building.equipe == equipe:
			print("non")
			continue
		var building_cell = tileMapManager.get_position_on_map(building.global_position)
		if unit_pos.distance_to(building_cell) <= unit.attack_range:
			await attack_target(unit, building)
			return

	

# --- MOUVEMENT GÉNÉRIQUE ---
func move_to_target(unit, target_pos):
	var move = unit.get_node("MovementManager")
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	tileMapManager.display_movement(unit)
	var cells = tileMapManager.get_reachable_cells(tileMapManager.MAP, unit_pos, unit.move_range)
	
	# Trouver la cellule la plus proche de la cible (comparaison sur la grille)
	var target_cell = tileMapManager.get_position_on_map(target_pos)
	var best_cell = null
	var best_dist = INF
	for cell in cells:
		var dist = cell.distance_to(target_cell)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
			
	if best_cell == null:
		return
		
	await get_tree().create_timer(0.5).timeout
	var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
	move.set_path(path)
	tileMapManager.highlight_reset()
	await get_tree().create_timer(1.75).timeout

# --- ATTAQUE ---
func attack_target(unit, target):
	tileMapManager.display_attack(unit)
	await get_tree().create_timer(0.5).timeout
	main._on_unit_attack(unit, target)
	unit.movement = true
	unit.attack = true

# --- RECHERCHE DE VILLAGE ---
func find_nearest_neutral_village(unit):
	var nearest = null
	var best_dist = INF
	for b in GameState.all_buildings:
		if ( b.buildingName == "Village" or b.buildingName == "Town" ) and b.equipe == 0:
			var dist = unit.global_position.distance_to(b.global_position)
			if dist < best_dist:
				best_dist = dist
				nearest = b
	return nearest
	
# --- RECHERCHE DE VILLAGE ENNEMI ---
func find_nearest_enemy_village(unit):
	var nearest = null
	var best_dist = INF
	for b in GameState.all_buildings:
		if ( b.buildingName == "Village" or b.buildingName == "Town" ) and b.equipe == 1:
			var dist = unit.global_position.distance_to(b.global_position)
			if dist < best_dist:
				best_dist = dist
				nearest = b
	return nearest

# --- RECHERCHE DU QG ENNEMI ---
func get_enemy_hq(equipe: int):
	for b in GameState.all_buildings:
		if b.buildingName == "QG" and b.equipe != equipe:
			return b
	return null
