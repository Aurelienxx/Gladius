extends Node


@onready var all_units := GameState.all_units

var liste_tank= []

var i=0

func search_tank():
	
	for tank in all_units:
		liste_tank=(tank)
		var taille_tank=len(liste_tank)
		if i<taille_tank:
			
			
			i=i+1
			
			
	
