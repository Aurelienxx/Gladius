extends Node2D

@onready var tilemap: TileMapLayer = $TileMapContainer/TileMap_Dirt
@onready var tank: Node = $Tank_unit  

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# On récupère la case cliquée
		var mouse_pos = get_global_mouse_position()
		var clicked_tile = tilemap.local_to_map(mouse_pos)
		
		# Si le tank est sélectionné, on lui donne l'ordre de bouger
		if tank.is_selected:
			tank.move_to(clicked_tile, tilemap)
