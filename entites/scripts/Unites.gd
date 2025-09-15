extends Node2D
class_name Unites

# --- Statistiques  ---
var nom : String
var cost: int
var upkeep: int
var hp: int
var damage: int
var move_range: int
var attack_range: int
var size: Vector2i

# --- Variables dynamiques ---
var current_hp: int

func _init(
		_name: String = "Unites",
		_cost: int = 0,
		_upkeep: int = 0,
		_hp: int = 0,
		_damage: int = 0,
		_move_range: int = 0,
		_attack_range: int = 0,
		_size: Vector2i = Vector2i(1,1)
	):
	name = _name
	cost = _cost
	upkeep = _upkeep
	hp = _hp
	current_hp = _hp
	damage = _damage
	move_range = _move_range
	attack_range = _attack_range
	size = _size
