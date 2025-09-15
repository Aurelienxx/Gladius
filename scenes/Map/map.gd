extends Node

func _ready():
	# Creation des tableaux et du nombre aléatoire
	var array_map = []
	var array_map_line = []
	var rng = RandomNumberGenerator.new()
	var random_number
	
	# Mise en forme des tableaux (50x30)
	array_map_line.resize(50)
	array_map.resize(30)
	
	# Remplissage de chaque ligne de la carte avec le tableau "ligne"
	array_map.fill(array_map_line)
	
	# Attribution d'une valeur aléatoire à chaque case de la carte
	for i in range(30):
		for j in range(50):
			random_number = rng.randi_range(0,4)
			array_map[i][j] = random_number

	# Affichage de la carte
	print(array_map)
