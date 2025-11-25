extends Node

@export var tileMapManager : Node
@export var main : Node

# Valeur des unités pour l'IA
var UNIT_VALUES = {
	"Infanterie": 5,
	"Artillerie": 10,
	"Camion": 1,
	"Tank": 15,
}

# --- LOGIQUE POUR L'IA DES CAMIONS ---
func Ai_Truck(unit):
	
	# Récupération de l'équipe qui est en train de jouer son tour ( 1 ou 2 )
	var equipe = unit.equipe   
	 # Récupération de toutes les unités présentes sur le terrain
	var all_units = GameState.all_units  
	 # Récupération de tous les bâtiments présents sur le terrain
	var all_buildings = GameState.all_buildings  
		
	# Récupération du village neutre le plus proche
	var neutral_village = find_nearest_neutral_village(unit)
	# Récupération du village ennemi le plus proche
	var enemy_village = find_nearest_enemy_village(unit)
	# Récupération de la base ennemi
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
	
	# Récupération de la position de l'unité qui doit attaquer
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	# Recherche de l'unité la plus intéressante à attaquer dans la liste des unités
	for verify_unit in all_units:
		# Si l'unité est dans l'équipe qui joue on passe à l'unité suivante avec le "continue"
		if verify_unit.equipe == equipe:
			continue
		# Récupération de la position de l'unité qui est vérifié
		var unit_cell = tileMapManager.get_position_on_map(verify_unit.global_position)
		# Vérification que l'unité est dans la portée d'attaque
		if unit_pos.distance_to(unit_cell) <= unit.attack_range:
			# Récupération de la valeur de l'unité
			var current_value = UNIT_VALUES.get(verify_unit.name_Unite, 0)
			# Vérification des points de vies de l'unité, si elle à autant ou moins de vie que l'unité attaquante, 
			# on ajoute des points à sa valeur
			if verify_unit.max_hp <= unit.damage:
				current_value += 15  # Ajout de 15 points à la valeur
			# Si la valeur de cette unité dépasse la valeur maximale précédente on remplace par cette unité
			if current_value > best_value:
				best_value = current_value
				best_unit = verify_unit

	# Vérification de la présence d'une unité dans la meilleure unité à portée d'attaque
	# Si une unité est présente on l'attaque et on met fin à la fonction avec "return"
	if best_unit != null:
		await attack_target(unit, best_unit)
		return

	# Recherche d’un bâtiment à portée d’attaque dans la liste de tous les bâtiments
	for building in all_buildings:
		# Si le bâtiment est possédé par l'équipe qui joue actuellement on passe au suivant avec "continue"
		if building.equipe == equipe:
			continue
		# Récupération de l'emplacement de ce bâtiment
		var building_cell = tileMapManager.get_position_on_map(building.global_position)
		# Si le bâtiment est dans la portée d'attaque il est attaqué.
		# les bâtiments sont trop éloignés pour qu'il soit nécessaire de vérifier lequel est le plus intéressant
		if unit_pos.distance_to(building_cell) <= unit.attack_range:
			await attack_target(unit, building)
			return

	

# --- MOUVEMENT GÉNÉRIQUE ---
# Utilisation de dijkstra déjà utilisé pour les unités sans IA
func move_to_target(unit, target_pos):
	# Récupération du script gérant les déplacements
	var move = unit.get_node("MovementManager")
	# Récupération de la position de l'unité 
	var unit_pos = tileMapManager.get_position_on_map(unit.global_position)
	# Récupération des cellules atteignables en fonction du terrain et de la porté de déplacement
	var cells = tileMapManager.get_reachable_cells(unit_pos, unit.move_range)
	
	# Récupération de la position de la case vers laquelle on souhaite se rendre
	var target_cell = tileMapManager.get_position_on_map(target_pos)
	var best_cell = null
	var best_dist = INF
	
	# Recherche de la case la plus proche de la cible parmi les cases atteignables
	for cell in cells:
		var dist = cell.distance_to(target_cell)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
			
	if best_cell == null:
		return
		
	# Délai de 0.5 secondes
	await get_tree().create_timer(0.5).timeout
	# Création du chemin 
	var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
	# Déplacement vers la case
	move.set_path(path)

# --- FONCTION D'ATTAQUE ---
func attack_target(unit, target):
	# Délai de 0.5 secondes
	await get_tree().create_timer(0.5).timeout
	# Réalisation de l'attaque
	
	main.attack_unit = unit
	main.try_attacking(target)
	unit.movement = true
	unit.attack = true

# --- FONCTION DE RECHERCHE DE VILLAGE NEUTRE ---
func find_nearest_neutral_village(unit):
	var nearest = null
	var best_dist = INF
	# Recherche parmi tous les bâtiments, le village neutre ( equipe == 0 ) le plus proche
	for b in GameState.all_buildings:
		if ( b.buildingName == "Village" or b.buildingName == "Town" ) and b.equipe == 0:
			# Récupération de la distance avec ce bâtiment
			var dist = unit.global_position.distance_to(b.global_position)
			# Si la distance est plus courte que le bâtiment précédent on choisi celui là 
			if dist < best_dist:
				best_dist = dist
				nearest = b
	return nearest
	
# --- FONCTION RECHERCHE DE VILLAGE ENNEMI ---
func find_nearest_enemy_village(unit):
	var nearest = null
	var best_dist = INF
	# Recherche parmi tous les bâtiments, le village ennemi le plus proche
	for b in GameState.all_buildings:
		if ( b.buildingName == "Village" or b.buildingName == "Town" ) and b.equipe != unit.equipe and b.equipe != 0:
			# Récupération de la distance avec ce bâtiment
			var dist = unit.global_position.distance_to(b.global_position)
			# Si la distance est plus courte que le bâtiment précédent on choisi celui là 
			if dist < best_dist:
				best_dist = dist
				nearest = b
	return nearest

# --- FONCTION DE RECHERCHE DU QG ENNEMI ---
func get_enemy_hq(equipe: int):
	# Recherche parmi les bâtiments lequel est le base ennemi
	for b in GameState.all_buildings:
		if b.buildingName == "QG" and b.equipe != equipe:
			# On renvoit directement ce bâtiment car chaque équipe n'en a qu'un
			return b
	return null
