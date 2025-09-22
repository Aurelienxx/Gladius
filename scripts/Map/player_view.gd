extends CharacterBody2D

@onready var cam: Camera2D = $Camera2D
var edge_margin := 150
var zoom_step := 0.5
var movement_speed = 500
var min_zoom := Vector2(0.5, 0.5)
var max_zoom := Vector2(3, 3)
var dragging := false
var last_mouse_pos := Vector2.ZERO

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		position.x -= movement_speed * delta
	if Input.is_action_pressed("ui_right"):
		position.x += movement_speed * delta
	if Input.is_action_pressed("ui_down"):
		position.y += movement_speed * delta
	if Input.is_action_pressed("ui_up"):
		position.y -= movement_speed * delta
	
	if not dragging:
		var viewport_size = get_viewport_rect().size
		var mouse_pos = get_viewport().get_mouse_position()
		var dir = Vector2.ZERO

		if mouse_pos.x < edge_margin:
			dir.x -= 1 - (mouse_pos.x / edge_margin)
		elif mouse_pos.x > viewport_size.x - edge_margin:
			dir.x += 1 - ((viewport_size.x - mouse_pos.x) / edge_margin)

		if mouse_pos.y < edge_margin:
			dir.y -= 1 - (mouse_pos.y / edge_margin)
		elif mouse_pos.y > viewport_size.y - edge_margin:
			dir.y += 1 - ((viewport_size.y - mouse_pos.y) / edge_margin)

		cam.offset += dir * movement_speed * delta
	else:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = mouse_pos - last_mouse_pos
		cam.offset -= delta_pos * 0.5
		last_mouse_pos = mouse_pos

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam.zoom = (cam.zoom + Vector2(zoom_step, zoom_step)).clamp(min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam.zoom = (cam.zoom - Vector2(zoom_step, zoom_step)).clamp(min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse_pos = get_viewport().get_mouse_position()
			else:
				dragging = false
