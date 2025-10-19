extends Node2D

var tile_size = 32
var score_map: Dictionary = {} 

func _draw():
	var min_score = INF
	var max_score = -INF
	for s in score_map.values():
		if s < min_score: min_score = s
		if s > max_score: max_score = s
	var score_range = max(max_score - min_score, 0.001)

	for cell in score_map.keys():
		var score = score_map[cell]
		var t = (score - min_score) / score_range
		var color = Color(1.0 - t, t, 0, 0.6)
		var pos = Vector2(cell.x * tile_size, cell.y * tile_size)
		draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), color)

func reset() -> void:
	score_map = {}
