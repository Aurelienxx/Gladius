extends Node
class_name Map

const ARRAY_LONG = 50
const ARRAY_HEIGHT = 30

@onready var tilemap_grass: TileMapLayer = $TileMap_Grass
@onready var tilemap_dirt: TileMapLayer = $TileMap_Dirt

var rng = RandomNumberGenerator.new()

func _ready():
	# Randomly generates a map using the tilesets
	""" 
	tilemap_grass.clear()
	tilemap_dirt.clear()
	
	var tab_grass_tile_placed = []
	var tab_dirt_placed = []
	
	for y in range(ARRAY_HEIGHT):
		for x in range(ARRAY_LONG):
			
			var pos = Vector2i(x, y)
			
			var source_id_dirt = 0
			var atlas_cord_dirt = Vector2i(1,1) 
			tilemap_dirt.set_cell(pos, source_id_dirt, atlas_cord_dirt)
			tab_dirt_placed.append(pos)
			
			var random_number = rng.randi_range(0, 10)
			if random_number==0:
				var source_id_grass = 0
				var atlas_cord_grass = Vector2i(4,1)
				tilemap_grass.set_cell(pos, source_id_grass, atlas_cord_grass)
				tab_grass_tile_placed.append(pos)
			
			
	tilemap_dirt.set_cells_terrain_connect(tab_dirt_placed, 0, 0, true)	
	tilemap_grass.set_cells_terrain_connect(tab_grass_tile_placed, 0, 0,false)
	"""
	
