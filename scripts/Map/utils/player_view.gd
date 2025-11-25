extends CharacterBody2D

@onready var cam: Camera2D = $Camera2D

const edge_margin := 50
const movement_speed = 650
const slide_speed = 10

var zoom_step := 0.5
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

	# Déplacement clavier
	# Certain son légérement élevé pour faire en sorte que si on appuis sur les opposé
	# on se déplace quand une direction 
	if Input.is_action_pressed("left"):
		velocity.x -= movement_speed * 1.1
	if Input.is_action_pressed("right"):
		velocity.x += movement_speed 
	if Input.is_action_pressed("down"):
		velocity.y += movement_speed 
	if Input.is_action_pressed("up"):
		velocity.y -= movement_speed * 1.1
	

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

		velocity += dir * movement_speed * 0.75

	# Déplacement par drag souris (clic gauche)
	else:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = mouse_pos - last_mouse_pos
		velocity -= delta_pos * 10 
		last_mouse_pos = mouse_pos
	
	# Mouvement avec glissement sur les obstacles
	if velocity != Vector2.ZERO:
		var collision = move_and_collide(velocity * delta)
		if collision:
			var normal = collision.get_normal()
			
			# Si on est face à un mur vertical (collision gauche/droite)
			if abs(normal.x) > abs(normal.y):
				# Glissement doux vers le bas
				var slide_dir = Vector2(0, 1) * slide_speed 
				move_and_collide(slide_dir * delta)
			else:
				# Sinon, comportement normal de glissement
				var slide = velocity.slide(normal)
				move_and_collide(slide * delta)

func _input(event):
	"""
	Gère les entrées souris pour le zoom et le drag de la caméra.
	- Molette ↑ : zoom avant
	- Molette ↓ : zoom arrière
	- Clic gauche maintenu : activer drag caméra
	"""
	if Input.is_action_just_released("MwU"):
		cam.zoom += Vector2(zoom_step, zoom_step)
		cam.zoom = cam.zoom.clamp(min_zoom, max_zoom)
	elif Input.is_action_just_released("MwD"):
		cam.zoom -= Vector2(zoom_step, zoom_step)
		cam.zoom = cam.zoom.clamp(min_zoom, max_zoom)
	
	# dragging
	elif Input.is_action_just_pressed("leftClick"):
		dragging = true
		last_mouse_pos = get_viewport().get_mouse_position()
	elif Input.is_action_just_released("leftClick"):
		dragging = false
