extends Entities
class_name Unites

var nom: String
var cost: int
var maintenance: int
var damage: int
var move_range: int
var attack_range: int

var grid_pos: Vector2i = Vector2i(-1, -1)


func _init(
	_nom: String = "Unité",
	_cost: int = 0,
	_maintenance: int = 0,
	_hp: int = 0,
	_damage: int = 0,
	_move_range: int = 0,
	_attack_range: int = 0,
	_texture: Texture2D = null
):
	super(_hp, _texture)
	
	nom = _nom
	cost = _cost
	maintenance = _maintenance
	damage = _damage
	move_range = _move_range
	attack_range = _attack_range
	

# Fonction d'attaque
func attack(target: Entities) -> void:
	target.get_damage(damage)
	

# Fonction permettant de placer une unité
func set_on_grid(new_grid_pos: Vector2i, cell_width: float, cell_height: float) -> void:
	grid_pos = new_grid_pos
	position = Vector2(grid_pos.x * cell_width, grid_pos.y * cell_height)
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		sprite.scale = Vector2(cell_width / tex_size.x, cell_height / tex_size.y)
