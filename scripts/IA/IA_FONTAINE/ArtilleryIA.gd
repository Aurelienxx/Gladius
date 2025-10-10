extends Node
class_name ArtilleryAI

var unit
var map_manager
var targeting_system

func _ready():
	unit = get_parent() 
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)



func init(_unit, _map_manager):
	unit = _unit
	map_manager = _map_manager
	targeting_system = ArtilleryTargeting.new()

func _on_new_player_turn(player:int):
	if unit.equipe == player:
		take_turn()  # l'unité IA joue automatiquement

func take_turn():
	if unit.current_hp <= 0:
		return
	
	var priority = ["Tank", "Infantry", "Building"]
	var target = targeting_system.choose_target(unit, priority)
	
	if target != null:
		print(unit.name_Unite, "attaque", target.name_Unite)
		# Ici on pourra appeler directement le manager pour attaquer
		map_manager.attack_unit(unit, target)
	else:
		print(unit.name_Unite, "se repositionne")
		# Ici on pourra calculer un déplacement pour se rapprocher d'une cible
