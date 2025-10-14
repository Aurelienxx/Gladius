extends Node2D

var selected_unit: CharacterBody2D # CharacterBody2D de l'unité séléctionnée

@onready var all_units := GameState.all_units
@onready var all_buildings := GameState.all_buildings

var quick_select_index = -1

var attack_unit: CharacterBody2D = null # CharacterBody2D de l'unité attaquée
var mode: String = "" # Mode d'action de l'unité séléctionnée

var current_player = GameState.current_player
@onready var tileMapManager = $TileMapContainer

func _ready():
	"""
	Initialise les connexions de signaux, récupère toutes les unités et bâtiments,
	et prépare la scène principale de jeu.
	"""
	# quand quelque chose est cliqué
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	GlobalSignal.Building_CLicked.connect(_on_building_click)
	
	GlobalSignal.Unit_Clicked.connect(_on_something_clicked)
	GlobalSignal.Building_CLicked.connect(_on_something_clicked)
	
	#
	GlobalSignal.Unit_Attack_Clicked.connect(_on_unit_attack)
	GlobalSignal.spawn_Unit.connect(spawnUnit)
		
	GlobalSignal.new_player_turn.connect(save_new_player)
	
	GlobalSignal.pass_turn.emit()

func save_new_player(player:int):
	current_player = player 

func _on_something_clicked(object:CharacterBody2D) -> void:
	if mode == "attack" and attack_unit != null and object != attack_unit:
		_on_unit_attack(attack_unit, object)

func _on_unit_clicked(unit: CharacterBody2D) -> void:
	"""
	Gère la sélection d'une unité pour le déplacement ou l'attaque.
	"""
	var manager: Node = unit.get_node("MovementManager")
	
	if manager.is_selected:
		selected_unit = unit
	
		# Vérifie que l'unité ne s'est pas déjà déplacée
		if unit.movement == false :
			mode = "move"
			
		# L’unité doit appartenir au joueur actif et ne pas avoir déjà bougé
		if selected_unit.equipe == current_player and selected_unit.movement == false:
			tileMapManager.display_movement(unit)
	else:
		tileMapManager.highlight_reset()
		
func _on_building_click(building: CharacterBody2D) -> void:
	if building.buildingName== "QG" and current_player == building.equipe:
		building.showUpgradeHUD(building.equipe)
	selected_unit = building
	
func _on_unit_attack(attacker: CharacterBody2D, target: CharacterBody2D):
	"""
	Gère le comportement lorsqu'une unité attaque une autre unité ou un bâtiment.
	Affiche également l'animation d'explosion et gère la mort des entités.
	"""
	if target == null:
		# Vérifie que l’attaquant appartient bien au joueur actif et qu’il n’a pas déjà attaqué
		if attacker.is_in_group("buildings") or attacker.equipe != current_player or attacker.attack == true:
			return

		attack_unit = attacker
		mode = "attack"
		tileMapManager.display_attack(attacker)
		return

	# Si la cible appartient à une équipe différente de celle de l'attaquant
	if target.equipe != attacker.equipe:
		var attacker_pos = attacker.global_position
		var building_cells = tileMapManager.get_occupied_cells(target) # Récupère la taille du bâtiment
		var attacker_cell = tileMapManager.get_position_on_map(attacker_pos) # Récupère la cellule de l'attaquant
		var in_range = false
		# Si une des cases du bâtiment est à portée d'attaque de l'unité, alors le bâtiment peut être attaqué par celle-ci
		for cell in building_cells:
			if attacker_cell.distance_to(cell) <= attacker.attack_range:
				in_range = true
				break
		
		if in_range:
			# Change les variables d’attaque et de mouvement pour rendre l’unité inactive pendant le reste du tour
			attacker.attack = true
			attacker.movement = true
			
			GlobalSignal.attack_occured_pos.emit(target.position)
			target.take_damage(attacker.damage) # Appelle la fonction de mise à jour de la barre de vie de la cible

			if target.current_hp <= 0:
				# Si c’est une unité
				if target.is_in_group("units"):
					# Supprime l'entité du terrain et de la liste des unités
					GameState.unregister_unit(target)
				else:
					# Supprime le Head Quarter et appelle la fonction de fin du jeu
					GameState.capture_building(target)

	attack_unit = null # L'unité n'attaque plus
	mode = "" # Réinitialise le mode 
	tileMapManager.highlight_reset()  # Supprime la surbrillance pour éviter la superposition

func move_manager() -> void:
	"""
	Gère les clics de souris sur la carte pour déplacer une unité.
	Ignore les clics si le mode attaque est actif ou si aucune unité n’est sélectionnée.

	:return: None
	"""
	var mouse_pos = get_global_mouse_position()
	var cell_position = tileMapManager.get_position_on_map(mouse_pos) # Récupère la position de la case cliquée
	var manager: Node = selected_unit.get_node("MovementManager")
	
	if tileMapManager.is_highlighted_cell(cell_position):
		# Si la case n'est pas occupé alors l'unité s'y déplace
		if not tileMapManager.is_cell_occupied(cell_position):
			var path = tileMapManager.make_path(selected_unit, cell_position, selected_unit.move_range) # Recherche du chemin de déplacement
			manager.set_path(path) # Déplace l'unité selon le chemin 
			selected_unit.movement = true # Change la variable de mouvement pour que l'unité ne puisse plus se déplacée durant le tour
			
	else:
		manager.is_selected = false
		
	selected_unit = null
	mode = "" 
	tileMapManager.highlight_reset()# Supprime la surbrillance pour éviter la superposition

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
			if unit.equipe == current_player and unit.movement == false:
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
				if unit.equipe == current_player and unit.attack == false:
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

func spawnUnit(unit) -> void:
	"""
	Fait apparaître une nouvelle unité pour le joueur actuel, si son économie le permet.

	:param unit: (Object) L’objet représentant le type d’unité à créer (nom, coût, maintenance, etc.).
	"""
	var spawn = get_node("Units/PlayerUnits")

	if EconomyManager.money_check(unit.cost):
		var new_unit = spawn.spawn_unit(unit.name_Unite,current_player) # Instancie une nouvelle unité dans léquipe
		add_child(new_unit) # Ajoute l'unité au terrain 
		all_units = get_tree().get_nodes_in_group("units") # Ajoute l'unité à la liste des unités
		# Mets à jour l'économie du joueur
		EconomyManager.buy_something(unit.cost)
		EconomyManager.change_money_loss(unit.maintenance)

func _input(event):
	"""
	Gère les raccourcis clavier pour changer de tour ou sélectionner rapidement une unité.

	:param event: (InputEvent) L’événement d’entrée clavier détecté.
	"""
	
	if Input.is_action_just_pressed("enter"):
		GlobalSignal.pass_turn.emit()
	elif Input.is_action_pressed("space"):
		quick_select()
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		pass
		#print("player truc : ",GameState.current_player)
		#print("Economy State : ",EconomyManager.EconomyTab)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if mode == "move": 
			move_manager()
