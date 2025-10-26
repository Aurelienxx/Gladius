extends Node2D

var tile_size = 32
var score_map: Dictionary = {}
var font: Font

func _ready():
	font = ThemeDB.fallback_font

func _draw():
	if score_map.is_empty():
		return

	var min_score = INF
	var max_score = -INF
	for s in score_map.values():
		min_score = min(min_score, s)
		max_score = max(max_score, s)

	var score_range = max(max_score - min_score, 0.001)

	for cell in score_map.keys():
		var score = score_map[cell]
		var t = clamp((score - min_score) / score_range, 0.0, 1.0)
		var color = Color(1.0 - t, t, 0.0, 0.6)
		var pos = Vector2(cell.x * tile_size, cell.y * tile_size)

		draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), color)

		if font:
			var score_text = str(round(score * 10) / 10.0) 
			var text_size = font.get_string_size(score_text)
			var text_pos = pos + Vector2((tile_size - text_size.x) / 2, tile_size * 0.65)
			draw_string(font, text_pos, score_text, tile_size)

func reset() -> void:
	score_map.clear()
	queue_redraw()
