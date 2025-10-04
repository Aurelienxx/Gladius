extends Node2D

@export var upgradeHUDScene : PackedScene = preload("res://scenes/UpgradeHUD/UpgradeHUD.tscn")
@export var unit_truck : PackedScene = preload("res://scenes/Entities/Units/TruckUnit.tscn")
@export var unit_artillery : PackedScene = preload("res://scenes/Entities/Units/ArtilleryUnit.tscn")
@export var unit_tank : PackedScene = preload("res://scenes/Entities/Units/TankUnit.tscn")
@export var unit_infantry : PackedScene = preload("res://scenes/Entities/Units/Infantry.tscn")
@export var head_quarter : PackedScene = preload("res://scenes/Entities/Building/QG.tscn")
@export var village : PackedScene = preload("res://scenes/Entities/Building/Village.tscn")
@export var ville : PackedScene = preload("res://scenes/Entities/Building/Town.tscn")

@onready var MAP: TileMapLayer = $"../../TileMapContainer/TileMap_Dirt"

@export var spawn_count: int = 8            
@export var spawn_radius: float = 100.0 # distance autour du point

@export var qg_positions: Array[Vector2] = [Vector2(-200, -250), Vector2(950, 500)]
@export var village_positions :  Array[Vector2] = [Vector2(-150, 50), Vector2(150, -250),Vector2(900, 200), Vector2(600, 500)]
@export var ville_position : Vector2 = Vector2(400, 200)

var currentHud: Control = null

func _ready() -> void:
	"""
	Initialise les bâtiments sur la carte : QG, villages et ville principale.
	"""
	# Création des Head Quarters
	for i in range(qg_positions.size()):
		create_building(head_quarter, qg_positions[i], i + 1)

	# Création des villages
	for pos in village_positions:
		create_building(village, pos, 0)

	# Création de la ville
	create_building(ville, ville_position, 0)


func create_building(building_scene: PackedScene, position: Vector2, equipe: int = 0) -> Node2D:
	"""
	Instancie un bâtiment sur la carte et le place sur la grille.

	:param building_scene: (PackedScene) La scène du bâtiment à créer.
	:param position: (Vector2) Position approximative où le bâtiment doit apparaître.
	:param equipe: (int) Équipe assignée au bâtiment (0 = neutre).
	:return: (Node2D) Le bâtiment instancié ou null si MAP non assigné.
	"""
	if MAP == null:
		push_error("Le MAP n’a pas été assigné !")
		return null

	var building = building_scene.instantiate()
	building.add_to_group("buildings")
	building.call_deferred("setup", equipe)

	# Snap sur la grille
	var cell = MAP.local_to_map(MAP.to_local(position))
	var snapped_pos = MAP.map_to_local(cell)
	building.position = MAP.position + snapped_pos

	add_child(building)
	return building


func spawn_unit(unit_type: String, actual_player: int):
	"""
	Instancie une unité autour du QG du joueur si une case libre est disponible.

	:param unit_type: (String) Type d’unité à créer ("Tank", "Infantry", "Truck", "Artillery").
	:param actual_player: (int) Numéro du joueur (1 ou 2).
	:return: (Node2D) L’unité instanciée ou null si aucune case libre disponible ou type invalide.
	"""
	var used_cells = MAP.get_used_cells()
	var unit
	
	# Récupère la position du QG du joueur
	var qg_pos = qg_positions[actual_player - 1]
	var qg_cell = MAP.local_to_map(MAP.to_local(qg_pos))
	
	if MAP.tile_set == null:
		push_error("Le MAP n’a pas de TileSet assigné !")
		return null
	
	var tile_size = float(MAP.tile_set.tile_size.x) 
	var radius_in_cells = int(spawn_radius / tile_size) + 1.5
	
	# Génère les cellules potentielles autour du QG
	var cells: Array[Vector2i] = []
	for x in range(-radius_in_cells + 1, radius_in_cells):
		for y in range(-radius_in_cells + 1, radius_in_cells):
			var candidate = qg_cell + Vector2i(x, y)
			if qg_cell.distance_to(candidate) <= radius_in_cells:
				if used_cells.has(candidate):
					cells.append(candidate)
					
	var occupied_positions = [] # Liste des positions déjà occupées par d’autres unités
	for current_unit in get_tree().get_nodes_in_group("units"):
		var cell_pos = MAP.local_to_map(MAP.to_local(current_unit.position))
		occupied_positions.append(cell_pos)
		
	# Ajouter le QG comme position occupée
	occupied_positions.append(MAP.local_to_map(MAP.to_local(qg_pos)))
	
	# Ajouter des positions autour du QG pour éviter le spawn trop proche
	var offsets = [
	Vector2(32, 0), Vector2(-32, 0),
	Vector2(0, 32), Vector2(0, -32),
	Vector2(32, 32), Vector2(32, -32),
	Vector2(-32, 32), Vector2(-32, -32)
	]

	for offset in offsets:
		var new_pos = qg_pos + offset
		occupied_positions.append(MAP.local_to_map(MAP.to_local(new_pos)))
		
	
	var free_cells = [] # Liste des cases vides
	for current_cell in cells:
		if current_cell not in occupied_positions:
			free_cells.append(current_cell)
			
	if free_cells.is_empty():
		return null
	
	# Choix aléatoire d’une cellule libre
	var cell = free_cells[randi() % free_cells.size()]
	
	# Instanciation de l’unité selon le type
	match unit_type:
		"Tank": unit = unit_tank.instantiate()
		"Infantry": unit = unit_infantry.instantiate()
		"Truck": unit = unit_truck.instantiate()
		"Artillery": unit = unit_artillery.instantiate()
		_: return null
	
	unit.call_deferred("setup", actual_player)
	unit.add_to_group("units") # Ajoute l'unité à au groupe des unités
	
	
	var local_pos = MAP.map_to_local(cell)
	unit.position = MAP.to_global(local_pos)
	return unit

func showUpgradeHud(unit: CharacterBody2D):
	if currentHud:
		currentHud.queue_free()
	currentHud = upgradeHUDScene.instantiate()
	get_tree().root.add_child(currentHud)
	var screen_pos = unit.get_viewport().get_camera_2d().unproject_position(unit.global_position)
	currentHud.position = screen_pos + Vector2(0, -100)
	# (optionnel) Si ton HUD est un Control dans un CanvasLayer
	currentHud.anchor_left = 0.5
	currentHud.anchor_top = 0.5
	currentHud.pivot_offset = currentHud.size / 2
	
