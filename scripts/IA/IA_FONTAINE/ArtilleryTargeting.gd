extends Node

class_name ArtilleryTargeting

# Fonction pour choisir la meilleure cible
# unit : l'unité artillerie
# priority_types : ordre de priorité des cibles (ex : ["Tank", "Infantry", "Building"])
func choose_target(unit, priority_types: Array):
	var enemies = []
	for uni in GameState.all_units:
		if uni.equipe != unit.equipe:
			enemies.append(uni)
	
	# Cherche la cible dans l'ordre de priorité
	for type_name in priority_types:
		for enemie in enemies:
			# Vérifie si la cible est à portée
			if unit.global_position.distance_to(enemie.global_position) <= unit.attack_range:
				if enemie.name_Unite == type_name:
					return enemie
	return null
