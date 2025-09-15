extends Node

const ARRAY_LONG = 50
const ARRAY_HEIGHT = 30
const CELL_SIZE = 32
const MARGIN_RATIO = 0.05

func _ready():
	var map = generate_map()
	display_map(map)
	
func generate_map() :
	"""génère un tableau de 50x30 de valeurs aléatoires comprises entre 0 et 4 inclus"""
	
	# Creation du tableau et du nombre aléatoire
	var array_map = []
	var rng = RandomNumberGenerator.new()
	var random_number
	array_map.resize(ARRAY_HEIGHT)
	
	for i in range(ARRAY_HEIGHT): # Pour chaque ligne
		# Initialisation de la ligne
		var array_map_line = []
		array_map_line.resize(ARRAY_LONG)
		
		# Attribution d'une valeur aléatoire à chaque case de la ligne
		for j in range(ARRAY_LONG):
			random_number = rng.randi_range(0,3)
			array_map_line[j] = random_number
			
		# Ajout de la ligne au tableau complet
		array_map[i] = array_map_line
		
	return array_map
		
func display_map(array_map):
	"""Affiche la carte donnée en paramètre"""
	
	var tiles = {
	0: preload("res://assets/sprites/grounds/grass.png"),
	1: preload("res://assets/sprites/grounds/mud.png"),
	2: preload("res://assets/sprites/grounds/barb_wire.png"),
	3: preload("res://assets/sprites/grounds/gaz.png"),
}


	# Affichage de la carte (array)
	print(array_map)
	
	#Affichage de la carte (sprites)
	var screen_size = get_viewport().get_visible_rect().size
	var cell_width = screen_size.x / ARRAY_LONG
	var cell_height = screen_size.y / ARRAY_HEIGHT
	
	for i in range(ARRAY_HEIGHT):
		for j in range(ARRAY_LONG):
			var tile_value = array_map[i][j]
			var sprite = Sprite2D.new()
			sprite.texture = tiles[tile_value]
			
			sprite.position = Vector2(j * cell_width, i * cell_height)
			
			var tex_size = sprite.texture.get_size()
			sprite.scale = Vector2(cell_width / tex_size.x, cell_height / tex_size.y)
			
			add_child(sprite)
	
	
