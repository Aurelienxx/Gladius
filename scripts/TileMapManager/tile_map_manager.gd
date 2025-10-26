extends Node2D

@onready var MAP: TileMapLayer = $TileMap_Dirt
@onready var HIGHLIGHT: TileMapLayer = $TileMap_Highlight
@onready var GRASS_MAP: TileMapLayer = $TileMap_Grass
@onready var GAZ: TileMapLayer = $TileMap_Gaz
@onready var OBSTACLE: TileMapLayer = $TileMap_Obstacle

var last_came_from: Dictionary = {} # Dictionnaire contenant, pour chaque case, la case précédente dans le chemin
var last_costs: Dictionary = {} # Dictionnaire des coûts de déplacement cumulés pour atteindre chaque case
var last_start: Vector2i # Position de départ utilisée pour le dernier calcul de chemin

var terrain_costs = {
	"TileMap_Obstacle": -1, # obstacle : infranchissable
	"TileMap_Dirt": 2,      # boue : coût double (50% de vitesse)
	"TileMap_Grass": 1,     # herbe : coût normal
	"TileMap_Gaz" : 2       # gaz : coût double (50% de vitesse)
}

@onready var all_units := GameState.all_units
@onready var all_buildings := GameState.all_buildings

func new_terrain_object_values(new_all_buildings, new_all_units):
	all_buildings = new_all_buildings
	all_units = new_all_units

func display_movement(unit:CharacterBody2D):
	var start_cell = get_position_on_map(unit.global_position)
	var reachable_cells = get_reachable_cells(start_cell, unit.move_range)
	highlight_cells(start_cell,reachable_cells)# Met en surbrillance les cases où l’unité peut se déplacer

func display_attack(unit:CharacterBody2D):
	var start_cell = get_position_on_map(unit.global_position) # Récupère la cellule de l'attaquant
	var attack_cells = get_attack_cells(start_cell, unit.attack_range) # Récupère la portée d’attaque de l'attaquant
	highlight_cells(start_cell, attack_cells, 1) # Met en surbrillance les cases attaquables
	
func highlight_reset():
	HIGHLIGHT.clear()

func get_position_on_map(_position:Vector2i):
	return MAP.local_to_map(_position)

func is_in_gaz(object):
	var object_position:Vector2i = get_position_on_map(object.global_position)
	var result = GAZ.get_cell_source_id(object_position) # -1 si pas dans le tileMapLayer
	if result != -1 : 
		return true
	else:
		return false

func is_highlighted_cell(_position) -> bool:
	var result = HIGHLIGHT.get_cell_source_id(_position) # -1 si pas dans le tileMapLayer
	if result != -1 : 
		return true
	else:
		return false 
	
func highlight_cells(start_cell, highlighted_cells, highlight_type: int = 0):
	"""
	Affiche les cases accessibles ou attaquables sur la carte.
	highlight_type = 0 : bleu (déplacement)
	highlight_type = 1 : rouge (attaque)
	"""
	HIGHLIGHT.clear() # Supprime la surbillance pour éviter la superposition 
	for cell in highlighted_cells:
		HIGHLIGHT.set_cell(cell, highlight_type, Vector2i(0,0))
	HIGHLIGHT.set_cell(start_cell, 2, Vector2i(0,0))

func gaz_cell(gaz_cells):
	"""
	Affiche les cases accessibles ou attaquables sur la carte.
	"""
	GAZ.clear() # Supprime la surbillance pour éviter la superposition 
	GAZ.set_cell(gaz_cells,0, Vector2i(0,0))

func get_terrain_cost(cell: Vector2i) -> int:
	"""
	Retourne le coût de déplacement pour une case donnée selon le terrain.
	"""
	if OBSTACLE.get_cell_source_id(cell) != -1:
		# Terrain est un obstacle
		return terrain_costs.get("TileMap_Obstacle")
	elif GAZ.get_cell_source_id(cell) != -1 :
		# Terrain est du gaz
		return terrain_costs.get("TileMap_Gaz")
	elif GRASS_MAP.get_cell_source_id(cell) != -1: 
		# Terrain est de l'herbe
		return terrain_costs.get("TileMap_Grass")
	elif MAP.get_cell_source_id(cell) != -1:
		# Terrain est de la terre
		return terrain_costs.get("TileMap_Dirt")
	return 1

func get_occupied_cells(unit: CharacterBody2D) -> Array:
	"""
	Retourne la liste des cases occupées par une unité ou un bâtiment sur la carte.
	Prend en compte la taille de l’entité si elle occupe plusieurs cases.
	"""
	var cells = [] # Liste des cases occupées
	var center_cell = MAP.local_to_map(unit.global_position) # Convertit la position en coordonnées de cellule

	# Définit la taille de l’unité (1x1 par défaut)
	var size_x = 1
	var size_y = 1
	if "size_x" in unit:
		size_x = unit.size_x
	if "size_y" in unit:
		size_y = unit.size_y

	# Parcourt toutes les cases couvertes par l’unité en fonction de sa taille
	for x in range(size_x):
		for y in range(size_y):
			var offset = Vector2i(x - size_x / 2, y - size_y / 2) # Calcule le décalage relatif à la case centrale
			cells.append(center_cell + offset) # Ajoute la cellule correspondante à la liste

	return cells # Retourne toutes les cellules occupées par l’unité


func get_reachable_cells(start: Vector2i, max_range: int) -> Array:
	"""
	Calcule toutes les cases accessibles depuis une position donnée sur la carte (algorithme de Dijkstra simplifié).
	Prend en compte les obstacles, le coût de déplacement et la portée maximale de l’unité.
	"""

	var reachable: Array = [] # Liste des cases accessibles
	last_came_from.clear() # Réinitialise les chemins précédemment calculés
	last_costs.clear() # Réinitialise les coûts de déplacement
	last_start = start # Sauvegarde de la position de départ

	# Dictionnaire des cases occupées (unités et bâtiments) pour un test rapide
	var occuppee := {}
	for unit in all_units:
		for cell in get_occupied_cells(unit):
			occuppee[cell] = true
	for building in all_buildings:
		for cell in get_occupied_cells(building):
			occuppee[cell] = true

	# File de priorité simulée (utilisée par l’algorithme de Dijkstra)
	var frontier: Array = []
	frontier.append({"pos": start, "cost": 0})
	last_came_from[start] = null
	last_costs[start] = 0

	# Directions possibles (haut, bas, gauche, droite)
	var neighbors = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	while frontier.size() > 0:
		# Extraction du noeud avec le plus petit coût
		var min_idx = 0
		var min_cost = frontier[0]["cost"]
		for i in range(1, frontier.size()):
			if frontier[i]["cost"] < min_cost:
				min_cost = frontier[i]["cost"]
				min_idx = i
		var current = frontier.pop_at(min_idx)
		var current_pos: Vector2i = current["pos"]
		var current_cost: int = current["cost"]

		# Ajoute la case atteinte si ce n’est pas la position de départ
		if current_pos != start:
			reachable.append(current_pos)

		# Explore les cases voisines
		for offset in neighbors:
			var next = current_pos + offset

			# Ignore les cases en dehors de la carte
			if MAP.get_cell_source_id(next) == -1:
				continue
			# Ignore les cases occupées par une unité ou un bâtiment (sauf la case de départ)
			if next != start and occuppee.has(next):
				continue

			var move_cost = get_terrain_cost(next)
			# Ignore les cases infranchissables
			if move_cost == -1:
				continue

			var new_cost = current_cost + move_cost
			# Ignore les cases hors de portée de déplacement
			if new_cost > max_range:
				continue

			# Si la case n’a pas encore été visitée ou qu’un chemin plus court est trouvé
			if not last_costs.has(next) or new_cost < last_costs[next]:
				last_costs[next] = new_cost
				last_came_from[next] = current_pos
				frontier.append({"pos": next, "cost": new_cost})

	return reachable # Retourne la liste des cases accessibles

func get_attack_cells(start: Vector2i, max_range: int) -> Array:
	"""
	Retourne les cases dans la portée d’attaque d’une unité.
	"""
	var cells = [] # Liste des cases attaquables
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var cell = start + Vector2i(x, y)
			if start.distance_to(cell) <= max_range:
				if MAP.get_cell_source_id(cell) != -1:
					cells.append(cell)
	return cells # Retourne les cases attaquables

func is_cell_occupied(cell: Vector2i) -> bool:
	"""
	Vérifie si une case est occupée par une unité ou un bâtiment.
	"""
	for unit in all_units:
		var occupied = get_occupied_cells(unit)
		if cell in occupied:
			return true # La case est occupée par une unité
	for unit in all_buildings:
		var occupied = get_occupied_cells(unit)
		if cell in occupied:
			return true # La case est occupée par un batiment
	return false # La case est libre

func make_path(unit: CharacterBody2D, goal: Vector2i, max_range: int) -> Array:
	"""
	Construit et retourne le chemin entre une position de départ et une destination donnée.
	Utilise les informations du dernier calcul de portée (Dijkstra) pour reconstruire le chemin le plus court.

	:param start: (Vector2i) Position de départ sur la grille.
	:param goal: (Vector2i) Position de destination sur la grille.
	:param max_range: (int) Distance maximale de déplacement autorisée pour l’unité.
	:return: (Array) Liste ordonnée de cases représentant le chemin à suivre.
	"""
	var start = get_position_on_map(unit.global_position)
	# Vérifie si un calcul précédent peut être réutilisé
	# Si les données sont vides ou si le point de départ a changé, on relance le calcul de portée
	if last_came_from.is_empty() or start != last_start:
		get_reachable_cells(start, max_range)

	# Si la destination n’a pas été atteinte dans le calcul précédent, le chemin est inaccessible
	if not last_came_from.has(goal):
		return []

	# Reconstruit le chemin depuis la destination jusqu’à la position de départ
	var path: Array = []
	var node = goal
	while node != null:
		path.insert(0, node) # Ajoute chaque case au début du tableau pour obtenir le bon ordre
		node = last_came_from[node] # Remonte vers la case précédente enregistrée

	return path # Retourne le chemin complet du départ à la destination

func is_adjacent_cells(a: Vector2i, b: Vector2i, range: int) -> bool:
	"""
	Vérifie si deux cases sont adjacentes dans un rayon donné.

	:param a: (Vector2i) Position de la première case.
	:param b: (Vector2i) Position de la deuxième case.
	:param range: (int) Rayon de proximité autorisé entre les deux cases.
	:return: (bool) True si les cases sont proches dans le rayon spécifié, False sinon.
	"""
	var dx = abs(a.x - b.x) # Distance x des deux cases
	var dy = abs(a.y - b.y) # Distance y des deux cases
	var result = dx <= range and dy <= range and not (dx == 0 and dy == 0) 
	return result # cases adjacentes uniquement

func attack_gaz(QG:CharacterBody2D)->void:
	"fonction qui attaque automatiquement une unité qui s'approche d'un QG"
	
	var pos_qg=MAP.local_to_map(QG.global_position)
	var liste=[]
	for unit in all_units:
		if unit.equipe != QG.equipe:
			var pos_unit=MAP.local_to_map(unit.global_position)
			if is_adjacent_cells(pos_qg,pos_unit,QG.attack_range):
				liste.append(pos_unit)
	if liste != []:
		var taille_liste= len(liste)
		var i :int=randi_range(0,taille_liste-1)
		gaz_cell(liste[i])

func get_valid_path(unit: CharacterBody2D, goal: Vector2i) -> Array:
	"""
	Retourne le chemin réalisable pour une unité vers un objectif donné.
	Le chemin est limité à la portée maximale de déplacement de l’unité (en prenant en compte les coûts terrain).
	"""
	var start = get_position_on_map(unit.global_position)
	var full_path = find_path_a_star(start, goal)

	var move_range = unit.move_range
	var valid_path: Array = []
	var total_cost = 0

	# On commence le chemin par la case de départ
	valid_path.append(full_path[0])

	# on parcours le chemin en prennant en compte le cout de déplacement
	for i in range(1, full_path.size()):
		var step = full_path[i]
		var step_cost = get_terrain_cost(step)
		
		if step_cost < 0:
			break
			
		total_cost += step_cost
		if total_cost > move_range:
			break

		valid_path.append(step)

	return make_path(unit,valid_path[-1],99)

	
func find_path_a_star(start: Vector2i, goal: Vector2i) -> Array:
	"""
	A* classique pour obtenir le chemin le plus court entre start et goal.
	Ignore uniquement les obstacles infranchissables.
	"""
	var open_list: Array = [start]
	var closed_list: Array = []
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: start.distance_to(goal)}

	# Directions possibles (4 directions)
	var directions = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

	while open_list.size() > 0:
		# Noeud avec le plus petit f_score
		var current = open_list[0]
		for node in open_list:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node

		# Si on atteint l'objectif, reconstruire le chemin
		if current == goal:
			var path: Array = []
			var node = current
			while node in came_from:
				path.insert(0, node)
				node = came_from[node]
			path.insert(0, start)
			return path

		open_list.erase(current)
		closed_list.append(current)

		for offset in directions:
			var neighbor = current + offset

			# Ignore les cases hors carte
			if MAP.get_cell_source_id(neighbor) == -1:
				continue

			# Ignore les obstacles infranchissables
			if get_terrain_cost(neighbor) < 0:
				continue
			
				
			if neighbor in closed_list:
				continue

			var tentative_g = g_score[current] + get_terrain_cost(neighbor)

			if neighbor not in open_list:
				open_list.append(neighbor)
			elif tentative_g >= g_score.get(neighbor, INF):
				continue

			# Mise à jour du chemin
			came_from[neighbor] = current
			g_score[neighbor] = tentative_g
			f_score[neighbor] = tentative_g + neighbor.distance_to(goal)

	# Si aucun chemin trouvé, retourne vide
	return []
