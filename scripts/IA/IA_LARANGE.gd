extends Node

@export var map : Node
@export var main : Node



# --- TOUR DE L'IA ---
func _ready() -> void:
	"""
	Connexion du signal de changement de tour pour commencer l'appel IA
	"""
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)

func _on_new_player_turn(player : int) -> void:
	"""Appel du tour IA pour le joueur 2"""
	for unit in GameState.all_units:
		if unit.equipe == GameState.current_player:
			# On remet les valeurs à false pour que les unités puissent agir
			unit.movement = false
			unit.attack = false
	# Appel du tour d'IA si c'est le tour du joueur 2
	if GameState.current_player == 2:
		IA_turn()

func IA_turn() -> void:
	"""
	Tour de l'IA, pour chaque unité
	Par ordre de priorité, tente d'attaquer ici puis
	définit une cible prioritaire où se rendre (ennemi faible, allié, bâtiment neutre/ennemi).
	gère ensuite le déplacement vers cette cible
	"""
	var all_units : Array = GameState.all_units
	
	for unit in all_units:
		if unit.equipe == GameState.current_player and not unit.movement and unit.name_Unite == "Infanterie":
			
			# ---- Initialisation des variable utilitaires ----
			var move : Node = unit.get_node("MovementManager")
			var target_cell : Variant = null # Cellule où se rendra l'unité
			var unit_pos : Vector2i = map.get_position_on_map(unit.global_position) # Position de l'unité sur le niveau
			var ally_nearby : CharacterBody2D = null # Allié proche potentiel
			var units_numbers : Array = get_units_numbers() # Nombre d'unités alliées/ennemies
			var nearby_target : CharacterBody2D = get_best_enemy_nearby(unit) # Ennemi rejoignable et attaquable ce tour
			var closest_building : CharacterBody2D = get_closest_building(unit,false,true) # Bâtiment NEUTRE le plus proche
			
			# 2x plus d'ennemis que d'alliés : On cherche un allié autour de soi (move_range*3)
			if units_numbers[1] > (units_numbers[0]*2) :
				ally_nearby = get_closest_ally_nearby(unit, 3)
			
			# On tente d'attaquer tout de suite, si réussi, on passe à l'unité suivante
			if await try_attacking_here(unit):
				continue
			
			# Affichage du range de déplacement pour simuler le comportement joueur, petite attente pour la même raison
			map.display_movement(unit)
			var reachable_cells : Array = map.get_reachable_cells(map.MAP, unit_pos, unit.move_range)
			await get_tree().create_timer(0.5).timeout
			
			# Si on ne peut pas bouger, on passe à l'unité suivante
			if reachable_cells.is_empty():
				continue
				
			# On a trouvé une cible faible à rejoindre puis attaquer ce tour
			elif nearby_target != null :
				print("INFANTERIE : Je me rapproche d'un ennemi pour l'attaquer")
				var target_pos : Vector2i = map.get_position_on_map(nearby_target.global_position)
				# On cherche à s'en approcher
				target_cell = get_closest_cell_to_target(unit_pos,reachable_cells, target_pos)
				
			# On a trouvé un allié à rejoindre
			elif ally_nearby != null:
				print("INFANTERIE : Il y a trop d'ennemis, je rejoins un allié")
				var ally_pos : Vector2i = map.get_position_on_map(ally_nearby.global_position)
				# On cherche à s'en approcher
				target_cell = get_closest_cell_to_target(unit_pos,reachable_cells, ally_pos)
				
			# On a trouvé un bâtiment neutre
			elif closest_building != null:
				print("INFANTERIE : Je me rapproche un bâtiment neutre pour le capturer")
				var building_cell : Vector2i = get_closest_building_cell(unit, closest_building) # Cellule à rejoindre (car bâtiments font 3*3)
				if building_cell != null:
					# On cherche à s'en approcher
					target_cell = get_closest_cell_to_target(unit_pos,reachable_cells, building_cell)
					
			# Pas de bâtiment neutre, on cherche un bâtiment ennemi
			elif closest_building == null:
				closest_building = get_closest_building(unit, true, false)
				if closest_building != null:
					print("INFANTERIE : Je rejoins un bâtiment ennemi pour l'attaquer")
					var building_cell : Vector2i = get_closest_building_cell(unit, closest_building) # Cellule à rejoindre (car bâtiments font 3*3)
					if building_cell != null:
						# On cherche à s'en approcher
						target_cell = get_closest_cell_to_target(unit_pos,reachable_cells, building_cell)

			# Aucun objectif détecté
			# NOTE : n'est pas censé de produire car le QG ennemi existe toujours 
			# et on a cherché un bâtiment ennemi avant cette condition
			elif target_cell == null:
				# Choix de cellule aléatoire
				target_cell = reachable_cells.pick_random()

			# Un objectif a été défini
			if target_cell != null:
				# On s'y rend
				var path : Array = map.make_path(unit,target_cell,unit.move_range)
				move.set_path(path)
				
				# Modification des valeurs et petite attente
				unit.movement = true
				map.highlight_reset()
				await get_tree().create_timer(0.5).timeout
				
				# On tente d'attaquer après le déplacement
				try_attacking_here(unit)


func get_units_numbers() -> Array :
	"""
	Renvoie l'état actuel de la partie
	return [nb_alliés,nb_ennemis] : Un tableau contenant le nombre d'alliés et d'ennemis
	"""
	var allies : int = 0
	var enemies : int = 0
	for unit in GameState.all_units :
		# Evolution des valeurs en fonction de l'équipe de l'unité itérée
		if unit.equipe == GameState.current_player :
			allies = allies + 1
		else :
			enemies = enemies + 1
	return [allies,enemies]




# ---- RECUPERATIONS D'UNITES ----
func get_enemy_targets() -> Array:
	"""
	Récupère TOUTES les cibles ennemies, unités et villages
	return targets : Un tableau contenant toutes les cibles ennemies
	"""
	var targets : Array = []
	
	# Ajout des unités adverses au tableau
	for unit in GameState.all_units:
		if unit.equipe != GameState.current_player:
			targets.append(unit)
			
	# Ajout des bâtiments adverses au tableau
	for building in GameState.all_buildings:
		if building.equipe != 0 and building.equipe != GameState.current_player:
			targets.append(building)
			
	return targets

func get_target_in_attack_range(unit : CharacterBody2D) -> CharacterBody2D:
	"""
	Recherche une cible a attaquer dans la portée d'attaque
	param unit : unité qui cherche des cibles
	return target | null : La cible se trouvant dans la portée d'attaque
	"""
	# Récupération de toutes les cibles et de ma position
	var targets : Array = get_enemy_targets()
	var unit_pos : Vector2i = map.get_position_on_map(unit.global_position)
	var enemy_target = null
	var building_target = null
	
	# Pour chaque cible, on cherche d'abord une unité dans la portée d'attaque
	for target in targets:
		if target in GameState.all_units:
			var target_pos = map.get_position_on_map(target.global_position)
			if unit_pos.distance_to(target_pos) <= unit.attack_range:
				enemy_target = target # Unité trouvée, on quitte la boucle
				break
		# Aucune unité trouvée,  on cherche un bâtiment dans la portée d'attaque
		elif target in GameState.all_buildings:
			var occupied_cells = map.get_occupied_cells(target)
			for cell in occupied_cells:
				if unit_pos.distance_to(cell) <= unit.attack_range:
					building_target = target # Bâtiment trouvé, on quitte la boucle
					break
	
	# On renvoie la sible trouvée si elle existe, priorité à une unité
	if enemy_target != null:
		return enemy_target
	elif building_target != null:
		return building_target
	return null

func get_best_enemy_nearby(unit : CharacterBody2D) -> CharacterBody2D :
	"""
	Récupération d'un ennemi faible proche
	param unit : unité qui cherche une ennemi à atteindre
	return target | null : La cible attaquable
	"""
	# NOTE : On va engager le combat vers une unité que si elle est faible
	
	# On récupère toutes les cibles ennemies
	var targets : Array = get_enemy_targets()
	var unit_pos: Vector2i = map.get_position_on_map(unit.global_position)
	if targets.is_empty() :
		return null
	
	# Si distance <= portée_mouvement + portée attaque
	# Autrement dit, si la cible sera attaquable juste après le déplacement
	for target in targets :
		var target_pos: Vector2i = map.get_position_on_map(target.global_position)

		if unit_pos.distance_to(target_pos) <= unit.move_range + unit.attack_range:
			# Si la cible a moins de vie que la capacité d'attaque de l'unité
			if target.current_hp <= unit.damage :
				return target
	return null


func get_ally_units() -> Array:
	"""
	Récupération de toutes les unités alliées
	return allies : Un tableau contenant toutes les unités de l'équipe actuelle
	"""
	var allies = []
	for unit in GameState.all_units:
		# Si une unité est de notre équipe, on l'ajoute au taleau
		if unit.equipe == GameState.current_player:
			allies.append(unit)
	return allies


func get_closest_ally_nearby(unit : CharacterBody2D, multiplicator_range : float) -> CharacterBody2D:
	"""
	Recherche de l'allié le plus proche dans un rayon de recherche donné
	param unit : l'unité qui cherche un allié
	param multiplicator_range : le rayon de recherche qui sera associé à la porté de déplacement de base
	return closest_ally | null : L'unité alliée la plus proche de l'unité unit
	"""
	# On récupère tous les alliés
	var allies = get_ally_units()
	if allies.is_empty():
		return null

	var unit_pos : Vector2i = map.get_position_on_map(unit.global_position)
	var proximity_range : float = unit.move_range * multiplicator_range # Portée de recherche de l'allié
	var closest_ally = null
	var closest_distance : float = INF

	for ally in allies:
		# On saute l'unité si elle est l'unité qui cherche un allié
		if ally == unit:
			continue

		var ally_pos : Vector2i = map.get_position_on_map(ally.global_position)
		var dist : float = unit_pos.distance_to(ally_pos)

		if dist <= proximity_range: # L'unité est dans la portée de recherche
			if dist < closest_distance:
				# Si elle est plus proche qu'une autre trouvée avant, on choisit celle-là
				closest_distance = dist
				closest_ally = ally

	return closest_ally
# ----------





# ---- RECUPERATIONS BATIMENTS ----
func get_target_buildings(unit : CharacterBody2D, include_enemy : bool, include_neutral : bool) -> Array:
	"""
	Renvoie les bâtiments neutres ou ennemis
	param unit : l'unité qui cherche un bâtiment à atteindre
	param include_enemy : True si on inclus les bâtiments ennemis dans notre recherche
	param include_neutral : True si on inclus les bâtiments neutres dans notre recherche
	return buildings : Tableau contenant tousles bâtiments correspondant aux critères
	"""
	
	var buildings : Array = []
	# Parcours de tous les bâtiments, on ajoute le bâtiment au tableau en fonction des conditions paramètres et de l'état de celui-ci
	for building in GameState.all_buildings:
		if include_neutral and building.equipe == 0:
			buildings.append(building)
		elif include_enemy and building.equipe != 0 and building.equipe != unit.equipe:
			buildings.append(building)
	return buildings


func get_closest_building(unit : CharacterBody2D, include_enemy : bool, include_neutral : bool) -> CharacterBody2D:
	"""
	Récupération du bâtiment le plus proche
	param unit : l'unité qui cherche un bâtiment à atteindre
	param include_enemy : True si on inclus les bâtiments ennemis dans notre recherche
	param include_neutral : True si on inclus les bâtiments neutres dans notre recherche
	return building[0] : Le bâtiment le plus proche de unit dans la liste ordonée des bâtiments ciblés
	"""
	# On récupère les bâtiments atteignable selon nos conditions
	var buildings : Array = get_target_buildings(unit, include_enemy, include_neutral)
	if buildings.is_empty():
		return null
	# Tri du tableau selon la distance entre l'unité et le bâtiment
	buildings.sort_custom(func(a, b): return unit.global_position.distance_to(a.global_position) < unit.global_position.distance_to(b.global_position))
	return buildings[0]


func get_closest_building_cell(unit : CharacterBody2D, building : CharacterBody2D) -> Variant:
	"""
	Récupération de la cellule de bâtiment la plus proche
	param unit : l'unité qui cherche à atteindre le bâtiment
	param building : le bâtiment atteignable
	return closest : La cellule de bâtiment atteignable la plus proche de unit
	"""
	# NOTE : Cette fonction existe car les bâtimets sont de taille 3x3, et peuvent donc être atteints de différentes façons
	
	# On récupère les cellules occupées par le bâtiment
	var occupied_cells : Array = map.get_occupied_cells(building)
	if occupied_cells.is_empty():
		return null
	
	var unit_pos : Vector2i = map.get_position_on_map(unit.global_position)
	var closest : Vector2i = occupied_cells[0]
	var min_dist : float = unit_pos.distance_to(closest)
	
	# Pour chaque cellule bâtiment
	for cell in occupied_cells:
		var dist : float = unit_pos.distance_to(cell)
		# Si la cellule est plus proche qu'une autre trouvée avant, on choisit celle-là
		if dist < min_dist:
			min_dist = dist
			closest = cell
			
	return closest
# ----------




# ---- ATTAQUE ET DEPLACEMENTS
func try_attacking_here(unit : CharacterBody2D) -> bool:
	"""
	Tentative d'attaque depuis la position actuelle
	param unit : unité qui tente d'attaquer
	return true | false : Si attaque réussie ou non
	"""
	# Recherche d'une cible attaquable dans la portée d'attaque
	var target = get_target_in_attack_range(unit)
	if target != null:
		# Cible trouvée, on l'attaque en simulant le comportement joueur (affichage et attente)
		map.display_attack(unit)
		await get_tree().create_timer(0.5).timeout
		main._on_unit_attack(unit, target)
		# Changement des valeurs, l'unité ne peut plus agir
		unit.movement = true
		unit.attack = true
		map.highlight_reset()
		await get_tree().create_timer(0.5).timeout
		return true
	return false

func get_closest_cell_to_target(unit_pos : Vector2i, reachable_cells : Array, target_pos : Vector2i) -> Variant:
	"""
	Renvoie la meilleure cellule atteignable vers une cible définie
	param unit_pos : La position de l'unité à déplacer
	param reachable_cells : Cellules atteignables par l'unité
	param target_pos : La position de la cible à atteindre
	return best_cell : La meilleure cellule atteignable pour se rapprocher le l'objectif target
	"""
	if reachable_cells.is_empty():
		return null
	
	# On calcule le meilleur chemin vers la cible avec le A*
	var path : Array = map.find_path_a_star(unit_pos, target_pos)
	var best_cell : Vector2i = reachable_cells[0]
	var best_score : float = INF
	
	# Parcours des cellules atteignables
	for cell in reachable_cells:
		
		# On choisit la cellule atteignable la plus proche du chemin
		# On peut légèrement dévier du chemin si ça nous rapproche de l'objectif
		var dist_to_target : float = cell.distance_to(target_pos)
		var dist_to_path : float = INF
		
		for path_cell in path:
			dist_to_path = min(dist_to_path, cell.distance_to(path_cell))
		
		var score : float = dist_to_target + dist_to_path * 0.5
		
		# Sélection de la meilleure cellule atteignable avec une attribution de score
		if score < best_score:
			best_score = score
			best_cell = cell
	
	return best_cell
