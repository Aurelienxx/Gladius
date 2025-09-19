extends CharacterBody2D

@export var move_speed: float = 200.0
var move_range: int
var is_selected := false
var path: Array = []
var target_position: Vector2
var is_moving := false
var map_ref: TileMapLayer

func setup(_move_range: int) -> void:
	move_range = _move_range

func _ready() -> void:
	GlobalSignal.Unit_Clicked.connect(_on_unit_clicked)
	$Area2D.clicked.connect(_on_shape_clicked)

func _on_unit_clicked(unit: CharacterBody2D):
	if unit != self:
		is_selected = false

func _on_shape_clicked():
	if not is_selected:
		is_selected = true
	GlobalSignal.Unit_Clicked.emit(self)

func set_path(new_path: Array, map: TileMapLayer):
	path = new_path
	map_ref = map
	move_to_next_cell()

func move_to_next_cell():
	if path.is_empty():
		is_moving = false
		return
	var next_cell: Vector2i = path.pop_front()
	target_position = map_ref.map_to_local(next_cell)
	is_moving = true

func _physics_process(delta):
	if is_moving:
		var direction = target_position - global_position
		if direction.length() > 2:
			velocity = direction.normalized() * move_speed
			move_and_slide()
		else:
			global_position = target_position
			velocity = Vector2.ZERO
			is_moving = false
			move_to_next_cell()
