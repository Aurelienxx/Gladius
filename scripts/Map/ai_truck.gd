extends Node

@export var tileMapManager : Node
@export var main : Node

# Valeur des unités pour l'IA
var UNIT_VALUES = {
	"Infanterie": 100,
	"Artillerie": 150,
	"Camion": 50,
	"Tank": 200,
	"QG": 300
}

const ATTACK_THRESHOLD = 0

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
	
	var best_target = null
	var best_value = 0
	
	# Recherche de cibles ennemies à portée
	for other in all_units:
		if other.equipe == equipe:
			continue
		var target_cell = tileMapManager.get_position_on_map(other.global_position)
		if target_cell in attack_cells:
			var value = UNIT_VALUES.get(other.name_Unite)
			if value > best_value:
				best_value = value
				best_target = other
	
	# Si une cible intéressante est trouvée : attaque
	if best_target != null and best_value >= ATTACK_THRESHOLD:
		await attack_target(unit, best_target)
		unit.movement = true
		unit.attack = true
		return
	
	# Sinon cherche un village neutre à capturer
	var village = find_nearest_village(unit)
	if village != null:
		await move_to_target(unit, village.global_position)
		unit.movement = true
		return
	
	# Sinon, avance vers le QG ennemi
	var enemy_hq = get_enemy_hq(equipe)
	if enemy_hq != null:
		await move_to_target(unit, enemy_hq.global_position)
		unit.movement = true
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
			
	await get_tree().create_timer(0.5).timeout
	var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
	move.set_path(path)
	tileMapManager.highlight_reset()
	await get_tree().create_timer(0.5).timeout

# --- ATTAQUE ---
func attack_target(attacker, target):
	var main = get_tree().get_first_node_in_group("MainScene")
	if main != null:
		main._on_unit_attack(attacker, target)

# --- RECHERCHE DE VILLAGE ---
func find_nearest_village(unit):
	var nearest = null
	var best_dist = INF
	for b in GameState.all_buildings:
		if b.buildingName == "Village" and b.equipe != unit.equipe:
			var dist = unit.global_position.distance_to(b.global_position)
			if dist < best_dist:
				best_dist = dist
				nearest = b
	return nearest

# --- RECHERCHE DU QG ENNEMI ---
func get_enemy_hq(equipe: int):
	for b in GameState.all_buildings:
		if b.buildingName == "HQ" and b.equipe != equipe:
			return b
	return null
