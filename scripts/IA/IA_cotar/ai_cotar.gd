extends Node
class_name ai_cotar

@export var tilemap:Node
@export var main: Node
@export var equipe_ia: int = 2


var controled_units:Array=[]
func _ready() -> void:
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)
	
func _on_new_player_turn(player: int):
	"""
	Exécuté à chaque début de tour. Si c’est le tour de l’équipe IA,
	elle sélectionne ses unités d’artillerie et exécute leurs décisions.
	:param player: (int) Numéro de l’équipe dont c’est le tour.
	"""
	if player != equipe_ia:
		return
	controled_units.clear()
	for unit in GameState.all_units:
		if unit.equipe == player and unit.name_Unite == "Tank":
			controled_units.append(unit)
			
	await bidule()
	controled_units.clear() 
	
func bidule()->void:
	for unit in controled_units:
		var move=unit.get_node("MovementManager")
		var attack_manager = unit.get_node("AttackManager") if unit.has_node("AttackManager") else null
		var unit_pos = tilemap.get_position_on_map(unit.global_position)
		
		var cell=tilemap.get_reachable_cells(tilemap.MAP,unit_pos, unit.move_range)
		if cell.is_empty():
			continue
		var target_cell=cell.pick_random()
		
		if target_cell != null:
			var path=tilemap.make_path(unit,target_cell,unit.move_range)
			move.set_path(path)
			

		
	
	
