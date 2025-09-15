extends Node

const ARRAY_LONG = 50
const ARRAY_HEIGHT = 30
const CELL_SIZE = 32

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
	for i in range(ARRAY_HEIGHT):
		for j in range(ARRAY_LONG):
			var sprite = Sprite2D.new()
			sprite.texture = tiles[array_map[i][j]]
			sprite.position = Vector2(j * CELL_SIZE, i * CELL_SIZE)

			var tex_size = sprite.texture.get_size()
			var scale_factor = CELL_SIZE / tex_size.x
			sprite.scale = Vector2(scale_factor, scale_factor)
			
			add_child(sprite)
	
	
