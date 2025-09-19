extends Entities
class_name Building



# --- Statistiques ---
var nom: String = "Building"
var lv: int = 1
var attack: int = 0
var attack_range: int = 10
var size_x: int = 3
var size_y: int = 3
var upgrade_cost: int = 0
# Variables dynamiques
var current_lv: int = 1
var zone_enabled: bool = false
var zone_radius: int = 0

func _init(
		_nom: String = "Building",
		_hp: int = 0,
		_attack: int = 0,
		_attack_range: int = 10,
		_upgrade_cost: int = 0,
		_lv: int = 1,
		_size_x: int = 3,
		_size_y: int = 3,
	) -> void:
	nom = _nom
	upgrade_cost = _upgrade_cost
	lv = _lv
	hp = _hp
	#current_hp = _hp
	current_lv = _lv
	attack = _attack
	attack_range = _attack_range
	size_x = _size_x
	size_y = _size_y

#func get_damage(damages: int) -> void:
	#current_hp = max(current_hp - damages, 0)
#
## --------------------
## Attaque d'une cellule
## --------------------
#func attack(target_x: int, target_y: int) -> void:
	#apply_damage_to_cell(target_x, target_y)
#
	## Attaque de zone si activée
	#if zone_enabled and zone_radius > 0:
		#_apply_area_damage(target_x, target_y)
#
## Appliquer les dégâts sur UNE case
#func apply_damage_to_cell(cell_x: int, cell_y: int) -> void:
	#var target = _get_entity_on_cell(cell_x, cell_y)
	#if target != null:
		#if target.has_method("get_damage"):
			#target.get_damage(attack)
		#else:
			#print("Cible trouvée mais pas de méthode get_damage() :", target)
	#else:
		#print("Aucune entité à la cellule (", cell_x, ",", cell_y, ")")
#
## Attaque de zone autour d'une case
#func _apply_area_damage(center_x: int, center_y: int) -> void:
	#for x in range(center_x - zone_radius, center_x + zone_radius + 1):
		#for y in range(center_y - zone_radius, center_y + zone_radius + 1):
			## Vérifie la distance au centre pour faire un cercle
			#if _distance(center_x, center_y, x, y) <= zone_radius:
				## Évite de réattaquer la cellule centrale si tu veux
				#if not (x == center_x and y == center_y):
					#apply_damage_to_cell(x, y)
#
## Fonction utilitaire pour calculer distance en int
#func _distance(x1: int, y1: int, x2: int, y2: int) -> float:
	#var dx = x1 - x2
	#var dy = y1 - y2
	#return sqrt(dx * dx + dy * dy)
