extends Node2D

const EndScreen = preload("res://scenes/EndScreen/EndScreen.tscn")
const TurnPanel = preload("res://scenes/HUD/turn_panel.tscn")

var selected_unit: CharacterBody2D # CharacterBody2D de l'unité séléctionnée
var all_units: Array = []
var all_buildings: Array = []

var quick_select_index = -1
@onready var playerView = $Player_view
@onready var anim_explosion = $AnimatedSprite2D
@onready var MAP: TileMapLayer = $TileMapContainer/TileMap_Dirt
@onready var HIGHLIGHT: TileMapLayer = $TileMapContainer/TileMap_Highlight
@onready var GRASS_MAP: TileMapLayer = $TileMapContainer/TileMap_Grass
@onready var GAZ: TileMapLayer = $TileMapContainer/TileMap_Gaz
@onready var OBSTACLE: TileMapLayer = $TileMapContainer/TileMap_Obstacle

var attack_unit: CharacterBody2D = null # CharacterBody2D de l'unité attaquée
var mode: String = "" # Mode d'action de l'unité séléctionnée


var last_came_from: Dictionary = {} # Dictionnaire contenant, pour chaque case, la case précédente dans le chemin
var last_costs: Dictionary = {} # Dictionnaire des coûts de déplacement cumulés pour atteindre chaque case
var last_start: Vector2i # Position de départ utilisée pour le dernier calcul de chemin

var actual_player = 1 
var turn_changing := false

var terrain_costs = {
	"TileMap_Obstacle": -1, # obstacle : infranchissable
	"TileMap_Dirt": 2,      # boue : coût double (50% de vitesse)
	"TileMap_Grass": 1,     # herbe : coût normal
	"TileMap_Gaz" : 2       # gaz : coût double (50% de vitesse)
}

func _ready():
	"""
	Initialise les connexions de signaux, récupère toutes les unités et bâtiments,
	et prépare la scène principale de jeu.
	"""
	anim_explosion.visible = false
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	GlobalSignal.Unit_Attack_Clicked.connect(_on_unit_attack)
	GlobalSignal.Next_Turn_Pressed.connect(next_player)
	GlobalSignal.spawn_Unit.connect(spawnUnit)
	
	all_units = get_tree().get_nodes_in_group("units") # Récupération des entités du groupe units
	all_buildings = get_tree().get_nodes_in_group("buildings") # Récupération des entités du groupe buildings


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

func _on_unit_clicked(unit: CharacterBody2D):
	"""
	Gère la sélection d'une unité pour le déplacement ou l'attaque.
	"""
	
	if mode == "attack" and attack_unit != null and unit != attack_unit:
		_on_unit_attack(attack_unit, unit)
		return
	
	var manager: Node = unit.get_node("MovementManager")
	selected_unit = unit
	
	# Vérifie que l'unité ne s'est pas déjà déplacée
	if unit.is_in_group("units"):
		if unit.movement == false :
			mode = "move"

	# Si l’unité appartient bien au groupe "units", on vérifie qu’elle peut se déplacer
	if unit.is_in_group("units"):
		if manager.is_selected:
			
			# L’unité doit appartenir au joueur actif et ne pas avoir déjà bougé
			if selected_unit.equipe == actual_player and selected_unit.movement == false:
				var start_cell = MAP.local_to_map(unit.global_position)
				var reachable_cells = get_reachable_cells(MAP, start_cell, unit.move_range)
				highlight_cells(start_cell,reachable_cells)# Met en surbrillance les cases où l’unité peut se déplacer
	if unit.is_in_group("buildings") and unit.getType() == "QG" and actual_player == unit.getTeam():
		unit.showUpgradeHUD(unit.getTeam())

func _on_unit_attack(attacker: CharacterBody2D, target: CharacterBody2D):
	"""
	Gère le comportement lorsqu'une unité attaque une autre unité ou un bâtiment.
	Affiche également l'animation d'explosion et gère la mort des entités.
	"""
	if target == null:
		# Vérifie que l’attaquant appartient bien au joueur actif et qu’il n’a pas déjà attaqué
		if attacker.is_in_group("buildings") or attacker.equipe != actual_player or attacker.attack == true:
			return

		attack_unit = attacker
		mode = "attack"

		HIGHLIGHT.clear()  # Supprime la surbrillance pour éviter la superposition

		var start_cell = MAP.local_to_map(attacker.global_position) # Récupère la cellule de l'attaquant
		var attack_cells = get_attack_cells(MAP, start_cell, attacker.attack_range) # Récupère la portée d’attaque de l'attaquant
		highlight_cells(start_cell, attack_cells, 1) # Met en surbrillance les cases attaquables
		return

	# Si la cible appartient à une équipe différente de celle de l'attaquant
	if target.equipe != attacker.equipe:
		var building_cells = get_occupied_cells(target) # Récupère la taille du bâtiment
		var attacker_cell = MAP.local_to_map(attacker.global_position) # Récupère la cellule de l'attaquant
		var in_range = false
		# Si une des cases du bâtiment est à portée d'attaque de l'unité, alors le bâtiment peut être attaqué par celle-ci
		for cell in building_cells:
			if attacker_cell.distance_to(cell) <= attacker.attack_range:
				in_range = true
				break

		if in_range:
			target.current_hp -= attacker.damage
			# Change les variables d’attaque et de mouvement pour rendre l’unité inactive pendant le reste du tour
			attacker.attack = true
			attacker.movement = true
			
			# Lance l'animation d'explosion sur l'unité attaquée
			anim_explosion.position = target.position
			anim_explosion.visible = true
			anim_explosion.z_index = 100
			anim_explosion.play("explosion")
			
			target.update_health_bar() # Appelle la fonction de mise à jour de la barre de vie de la cible
			
			if target.current_hp <= 0:
				
				# Si la cible est un bâtiment autre que le Head Quarter
				if target.is_in_group("buildings") and target.get_script().resource_path.find("QG.gd") == -1:
					# Réapparaît en neutre
					target.equipe = 0
					target.current_hp = target.max_hp
					target._apply_color(0)
					
				# Si c’est une unité
				elif target.is_in_group("units"):
					# Supprime l'entité du terrain et de la liste des unités
					all_units.erase(target)
					target.queue_free()
				else:
					# Supprime le Head Quarter et appelle la fonction de fin du jeu
					all_units.erase(target)
					target.queue_free()
					if target.equipe == 1:
						GameOver(2)
					else:
						GameOver(1) 
						
	attack_unit = null # L'unité n'attaque plus
	mode = "" # Réinitialise le mode 
	HIGHLIGHT.clear()  # Supprime la surbrillance pour éviter la superposition


func GameOver(team: int):
	"""
	Affiche l’écran de fin de partie pour l’équipe gagnante.
	"""
	var game_over = EndScreen.instantiate()
	add_child(game_over)
	game_over.change_result(team)
	get_tree().paused = true

func get_reachable_cells(map: TileMapLayer, start: Vector2i, max_range: int) -> Array:
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
			if map.get_cell_source_id(next) == -1:
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



func get_attack_cells(map: TileMapLayer, start: Vector2i, max_range: int) -> Array:
	"""
	Retourne les cases dans la portée d’attaque d’une unité.
	"""
	var cells = [] # Liste des cases attaquables
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var cell = start + Vector2i(x, y)
			if start.distance_to(cell) <= max_range:
				if map.get_cell_source_id(cell) != -1:
					cells.append(cell)
	return cells # Retourne les cases attaquables

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

func make_path(start: Vector2i, goal: Vector2i, max_range: int) -> Array:
	"""
	Construit et retourne le chemin entre une position de départ et une destination donnée.
	Utilise les informations du dernier calcul de portée (Dijkstra) pour reconstruire le chemin le plus court.

	:param start: (Vector2i) Position de départ sur la grille.
	:param goal: (Vector2i) Position de destination sur la grille.
	:param max_range: (int) Distance maximale de déplacement autorisée pour l’unité.
	:return: (Array) Liste ordonnée de cases représentant le chemin à suivre.
	"""

	# Vérifie si un calcul précédent peut être réutilisé
	# Si les données sont vides ou si le point de départ a changé, on relance le calcul de portée
	if last_came_from.is_empty() or start != last_start:
		get_reachable_cells(MAP, start, max_range)

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


func _unhandled_input(event):
	"""
	Gère les clics de souris sur la carte pour déplacer une unité.
	Ignore les clics si le mode attaque est actif ou si aucune unité n’est sélectionnée.

	:param event: (InputEvent) L’événement d’entrée (clic ou touche).
	:return: None
	"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == "attack":
			return

		if selected_unit == null:
			return
			
		if not selected_unit.is_in_group("units"):
			HIGHLIGHT.clear()
			return
			
		var mouse_pos = get_global_mouse_position()
		var clicked_cell = MAP.local_to_map(mouse_pos) # Récupère la position de la case cliquée
		if HIGHLIGHT.get_cell_source_id(clicked_cell) != -1:
			# Si la case n'est pas occupé alors l'unité s'y déplace
			if not is_cell_occupied(clicked_cell):
				var path = make_path(MAP.local_to_map(selected_unit.global_position), clicked_cell, selected_unit.move_range) # Recherche du chemin de déplacement
				var manager: Node = selected_unit.get_node("MovementManager")
				manager.set_path(path, MAP) # Déplace l'unité selon le chemin 
				HIGHLIGHT.clear() # Supprime la surbrillance pour éviter la superposition
				selected_unit.movement = true # Change la variable de mouvement pour que l'unité ne puisse plus se déplacée durant le tour
				check_building_capture(selected_unit) # Capture automatique


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


func check_building_capture(unit: CharacterBody2D):
	"""
	Vérifie si une unité peut capturer un bâtiment situé à proximité immédiate.

	:param unit: (CharacterBody2D) L’unité tentant de capturer un bâtiment.
	:return: None
	"""
	var unit_cell = MAP.local_to_map(unit.global_position)
	var radius = 64
	var tile_size = 32    # à adapter selon ton jeu
	var radius_in_cells = int(radius / tile_size) + 1.5
	for building in all_buildings:
		var building_cell = MAP.local_to_map(building.global_position)

		# Capture si le bâtiment est neutre et dans le rayon
		if building.equipe == 0 and is_adjacent_cells(unit_cell, building_cell, radius_in_cells):
			print("Capture réussie !")
			building.capture(unit.equipe)


func next_player():
	"""
	Passe le tour au joueur suivant.
	Réinitialise les actions des unités et met à jour les ressources de chaque joueur.
	"""
	if turn_changing:
		return 

	turn_changing = true
	HIGHLIGHT.clear()
	
	for build in all_buildings:
		if build.get_script().resource_path.find("QG.gd") != -1 and build.equipe == actual_player and build.lv==3:
			attack_gaz(build)
	for unit in all_units:
		if unit.equipe == actual_player:
			unit.movement = false
			unit.attack = false
			
			
			# Si une unité du joueur est dans une case gaz alors elle prends des dégats
			if GAZ.get_cell_source_id(MAP.local_to_map(unit.global_position)) != -1 :
				unit.current_hp -= 25
				unit.update_health_bar() # Appelle la fonction de mise à jour de la barre de vie de la cible
				if unit.current_hp <= 0:
					# Supprime l'entité du terrain et de la liste des unités
					all_units.erase(unit)
					unit.queue_free()
			
	unit_economy()
	buildingt_economy()

	# Si le joueur actuel est 1 (bleu) alors on passe au joueur 2 (rouge) puis mets à jour l'argent du joueur 2
	if actual_player == 1:
		actual_player = 2
		EconomyManager.money_result2 = EconomyManager.money_gain2 - EconomyManager.money_loss2
		EconomyManager.current_money2 = EconomyManager.economy_turn(EconomyManager.current_money2,EconomyManager.money_result2)
		
	else :
		actual_player = 1
		
		EconomyManager.money_result1 = EconomyManager.money_gain1 - EconomyManager.money_loss1
		EconomyManager.current_money1 = EconomyManager.economy_turn(EconomyManager.current_money1,EconomyManager.money_result1)
	
	var turn_panel = TurnPanel.instantiate()
	add_child(turn_panel)
	await turn_panel.show_turn_async(actual_player)
	turn_changing = false

func quick_select():
	"""
	Sélectionne automatiquement la prochaine unité du joueur pouvant se déplacer ou attaquer.
	Si aucune unité ne peut se déplacer, cherche une unité pouvant encore attaquer.
	"""
	
	if all_units.size() != 0:
		var moved = false
		# Commence la recherche à l’unité suivante après la dernière sélectionnée
		var currently_selected_unit = (quick_select_index + 1) % all_units.size()
		var unit_index = currently_selected_unit

		# Boucle pour trouver une unité pouvant encore se déplacer
		while true:
			var unit = all_units[unit_index]
			if unit.equipe == actual_player and unit.movement == false:
				# Sélectionne l’unité et déclenche la logique de déplacement
				var manager: Node = unit.get_node("MovementManager")
				manager.is_selected = true
				_on_unit_clicked(unit)
				moved = true
				quick_select_index = unit_index  # Mémorise l’unité sélectionnée
				# Déplace la caméra sur l’unité sélectionnée
				var pos = unit.position
				var cam = get_node("./Player_view")
				cam.global_position = pos # Centre la caméra sur l'unité séléctionnée
				break

			# Passe à l’unité suivante dans la liste
			unit_index = (unit_index + 1) % all_units.size()
			# Si on a fait un tour complet, arrête la boucle
			if unit_index == currently_selected_unit:
				break

		# Si aucune unité n’a pu se déplacer, cherche une unité pouvant attaquer
		if not moved:
			unit_index = currently_selected_unit
			while true:
				var unit = all_units[unit_index]
				if unit.equipe == actual_player and unit.attack == false:
					# Sélection automatique pour l’attaque
					_on_unit_attack(unit, null)
					# Déplace la caméra sur l’unité
					var pos = unit.position
					var cam = get_node("./Player_view")
					cam.global_position = pos
					quick_select_index = unit_index
					break

				unit_index = (unit_index + 1) % all_units.size()
				if unit_index == currently_selected_unit:
					break


func unit_economy():
	"""
	Met à jour les coûts d’entretien des unités pour chaque joueur.
	"""
	EconomyManager.money_loss1 = 0
	EconomyManager.money_loss2 = 0

	for unit in all_units:
		if unit.equipe == 1:
			EconomyManager.money_loss1 += unit.maintenance
		elif unit.equipe == 2:
			EconomyManager.money_loss2 += unit.maintenance
	
func buildingt_economy():
	"""
    Met à jour les gains des bâtiments capturés pour chaque joueur.
    """
	EconomyManager.money_gain1 = 0
	EconomyManager.money_gain2 = 0
	

	for buiding in all_buildings:
		if buiding.equipe == 1:
			EconomyManager.money_gain1 += buiding.current_gain
		elif buiding.equipe == 2:
			EconomyManager.money_gain2 += buiding.current_gain
	
func _input(event):
	"""
	Gère les raccourcis clavier pour changer de tour ou sélectionner rapidement une unité.

	:param event: (InputEvent) L’événement d’entrée clavier détecté.
	"""
	if Input.is_action_just_pressed("enter"):
		next_player()
	if Input.is_action_pressed("space"):
		quick_select()

func spawnUnit(unit) -> void:
	"""
	Fait apparaître une nouvelle unité pour le joueur actuel, si son économie le permet.

	:param unit: (Object) L’objet représentant le type d’unité à créer (nom, coût, maintenance, etc.).
	"""
	var spawn = get_node("Units/PlayerUnits")

	# Si le joueur est le 1 (bleu)
	if actual_player == 1:
		# Vérifie que l'économie du joueur permet d'acheter une unité
		if EconomyManager.current_money1 >= unit.cost:
			
			var new_unit = spawn.spawn_unit(unit.name_Unite,actual_player) # Instancie une nouvelle unité dans léquipe
			add_child(new_unit) # Ajoute l'unité au terrain 
			all_units = get_tree().get_nodes_in_group("units") # Ajoute l'unité à la liste des unités
			
			# Mets à jour l'économie du joueur
			EconomyManager.current_money1 = EconomyManager.buy_something(EconomyManager.current_money1, unit.cost)
			EconomyManager.money_loss1 = EconomyManager.change_money_loss(EconomyManager.money_gain1, EconomyManager.money_loss1, unit.maintenance)

	else:
		# Vérifie que l'économie du joueur permet d'acheter une unité
		if EconomyManager.current_money2 >= unit.cost:
			
			var new_unit = spawn.spawn_unit(unit.name_Unite,actual_player) # Instancie une nouvelle unité dans léquipe
			add_child(new_unit) # Ajoute l'unité au terrain 
			all_units = get_tree().get_nodes_in_group("units") # Ajoute l'unité à la liste des unités
			
			# Mets à jour l'économie du joueur
			EconomyManager.current_money2 = EconomyManager.buy_something(EconomyManager.current_money2, unit.cost)
			EconomyManager.money_loss2 = EconomyManager.change_money_loss(EconomyManager.money_gain2, EconomyManager.money_loss2, unit.maintenance)
		

func _on_animated_sprite_2d_animation_finished() -> void:
	"""
	Cache l’animation d’explosion une fois terminée.
	"""
	anim_explosion.visible = false

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
		
		
			 
		
