extends Node

@export var map : Node 
@export var main : Node
#@onready var move = get_node("res://scripts/Entities/Units/InfantryUnit")

func _ready() -> void:
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)
	
func _on_new_player_turn(player : int) -> void:
	for unit in GameState.all_units:
		if unit.equipe == GameState.current_player:
			unit.movement = false
	if GameState.current_player == 2:
		movement()

func movement() -> void:
	var all_units = GameState.all_units
	if all_units != [] :
		for unit in all_units :
			if unit.equipe == GameState.current_player and unit.movement == false:
				var move = unit.get_node("MovementManager")
				
				map.display_movement(unit)
				var unit_pos = map.get_position_on_map(unit.global_position)
				var cells = map.get_reachable_cells(map.MAP,unit_pos,unit.move_range)
				await get_tree().create_timer(0.5).timeout
				
				var cell = cells.pick_random()
				var path = map.make_path(unit,cell,unit.move_range)
				move.set_path(path)
				unit.movement = true
				map.highlight_reset()
				
				await get_tree().create_timer(0.5).timeout
