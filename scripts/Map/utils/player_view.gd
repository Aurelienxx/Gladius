extends CharacterBody2D

@onready var cam: Camera2D = $Camera2D
var edge_margin := 50
var zoom_step := 0.5
var movement_speed = 500
var min_zoom := Vector2(1, 1)
var max_zoom := Vector2(3, 3)
var dragging := false
var last_mouse_pos := Vector2.ZERO

func _physics_process(delta: float) -> void:
	"""
	Gère le déplacement de la caméra à chaque frame physique.
	Le mouvement peut se faire via :
	- les touches directionnelles,
	- la souris au bord de l’écran,
	- le drag à la souris (clic gauche maintenu).
	"""
	velocity = Vector2.ZERO

	var zoom_factor = cam.zoom.x  

	# Déplacement clavier
	if Input.is_action_pressed("left"):
		velocity.x -= movement_speed * zoom_factor
	if Input.is_action_pressed("right"):
		velocity.x += movement_speed * zoom_factor
	if Input.is_action_pressed("down"):
		velocity.y += movement_speed * zoom_factor
	if Input.is_action_pressed("up"):
		velocity.y -= movement_speed * zoom_factor

	# Déplacement au bord de l’écran (si pas en drag souris)
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

		velocity += dir * movement_speed * zoom_factor
		velocity *= 0.5
		
	# Déplacement par drag souris (clic gauche)
	else:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = mouse_pos - last_mouse_pos
		velocity -= delta_pos * 10 * zoom_factor  
		last_mouse_pos = mouse_pos

	move_and_collide(velocity * delta)


func _input(event):
	"""
	Gère les entrées souris pour le zoom et le drag de la caméra.
	- Molette ↑ : zoom avant
	- Molette ↓ : zoom arrière
	- Clic gauche maintenu : activer drag caméra
	"""
	if event is InputEventMouseButton:
		# Zoom avec la molette
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam.zoom += Vector2(zoom_step, zoom_step)
			cam.zoom = cam.zoom.clamp(min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam.zoom -= Vector2(zoom_step, zoom_step)
			cam.zoom = cam.zoom.clamp(min_zoom, max_zoom)
		
		# Drag caméra avec clic gauche
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				last_mouse_pos = get_viewport().get_mouse_position()
			else:
				dragging = false

func setCameraLimits(tMap: TileMapLayer):
	var usedRect: Rect2 = tMap.get_used_rect()
	var cellSize: Vector2i = tMap.tile_set.tile_size
	var limiteMapGauche = usedRect.position.x * cellSize.x
	var limiteMapDroite = (usedRect.position.x + usedRect.size.x) * cellSize.x
	var limiteMapHaut = usedRect.position.y * cellSize.y
	var limiteMapBas = (usedRect.position.y + usedRect.size.y) * cellSize.y
	
	cam.limit_left = limiteMapGauche
	cam.limit_right = limiteMapDroite
	cam.limit_top = limiteMapHaut
	cam.limit_bottom = limiteMapBas
