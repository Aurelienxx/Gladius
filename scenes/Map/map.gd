extends Node

const ARRAY_LONG = 50
const ARRAY_HEIGHT = 30

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
			random_number = rng.randi_range(0,4)
			array_map_line[j] = random_number
			
		# Ajout de la ligne au tableau complet
		array_map[i] = array_map_line
		
	return array_map
		
func display_map(array_map):
	"""Affiche la carte donnée en paramètre"""
	# Affichage de la carte
	print(array_map)
