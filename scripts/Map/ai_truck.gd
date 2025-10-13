extends Node

@export var tileMapManager : Node

# Valeur des unités pour l'IA
var UNIT_VALUES = {
	"Infanterie": 100,
	"Camion": 50,
	"Tank": 200,
	"QG": 300
}

const ATTACK_THRESHOLD = 120

var all_units = GameState.all_units
var all_buildings = GameState.all_buildings

func _ready():
	# Connexion au signal de début de tour
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)

func _on_new_player_turn(player: int) -> void:
	# Si c'est le tour de l'IA (équipe 2)
	if player == 2:
		Ai_Truck(player)

func Ai_Truck(equipe: int) -> void:
	for unit in all_units:
		# Ne traiter que les camions de l'IA
		if unit.equipe != equipe or unit.name_Unite != "Camion":
			continue

		# Ignorer si l'unité a déjà bougé ou attaqué
		if unit.movement or unit.attack:
			continue

		# Position de départ sur la grille
		var start = tileMapManager.get_position_on_map(unit.global_position)
		# Cases attaquables depuis cette position
		var attack_cells = tileMapManager.get_attack_cells(tileMapManager.MAP, start, unit.attack_range)

		# Cherche la meilleure cible ennemie à portée
		var best_target = null
		var best_value = 0
		for other in all_units:
			if other.equipe == equipe:
				continue
			var target_cell = tileMapManager.get_position_on_map(other.global_position)
			if target_cell in attack_cells:
				var value = UNIT_VALUES.get(other.name_Unite, 50)
				if value > best_value:
					best_value = value
					best_target = other

		# Si on a une cible valable, attaque directement
		if best_target != null and best_value >= ATTACK_THRESHOLD:
			attack_target(unit, best_target)
			continue

		# Sinon, cherche un village neutre à proximité
		var village = find_nearest_village(unit)
		if village != null:
			move_to_target(unit, village.global_position)
			continue

		# Sinon, avance vers le QG ennemi
		var enemy_hq = get_enemy_hq(equipe)
		if enemy_hq != null:
			move_to_target(unit, enemy_hq.global_position)

# Fonction pour trouver le village neutre le plus proche
func find_nearest_village(unit):
	var nearest = null
	var best_dist = INF
	for b in all_buildings:
		if b.buildingName == "Village" and b.equipe != unit.equipe:
			var dist = unit.global_position.distance_to(b.global_position)
			if dist < best_dist:
				best_dist = dist
				nearest = b
	return nearest

# Fonction pour récupérer le QG ennemi
func get_enemy_hq(equipe: int):
	for b in all_buildings:
		if b.buildingName == "QG" and b.equipe != equipe:
			return b
	return null

# Déplacement via MovementManager et set_path
func move_to_target(unit, target_pos):
	# Cellule cible sur la grille
	var target_cell = tileMapManager.get_position_on_map(target_pos)
	# Chemin jusqu'à la cellule cible
	var path = tileMapManager.make_path(unit, target_cell, unit.move_range)

	if path.size() == 0:
		return # Aucun chemin disponible

	# Récupère le MovementManager de l'unité
	var manager = unit.get_node("MovementManager")
	if manager:
		manager.set_path(path) # Lance le déplacement animé
		unit.movement = true # Marque l'unité comme ayant bougé

# Fonction pour attaquer une unité cible
func attack_target(attacker, target):
	var main = get_tree().get_first_node_in_group("MainScene")
	if main != null:
		main._on_unit_attack(attacker, target)
