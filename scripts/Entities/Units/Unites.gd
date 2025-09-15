extends Node2D
class_name Unites

# Statistiques
var nom : String
var cost: int
var maintenance: int
var hp: int
var damage: int
var move_range: int
var attack_range: int

# Variable dynamique
var current_hp: int


# Initalisation des statistiques de l'unité
func _init(
		_name: String = "Unites",
		_cost: int = 0,
		_maintenance: int = 0,
		_hp: int = 0,
		_damage: int = 0,
		_move_range: int = 0,
		_attack_range: int = 0,
		_size: Vector2i = Vector2i(1,1)
	):
	name = _name
	cost = _cost
	maintenance = _maintenance
	hp = _hp
	current_hp = _hp
	damage = _damage
	move_range = _move_range
	attack_range = _attack_range
	

# Fonction de réception des dégâts
func get_damage(damages: int) -> void:
	current_hp = max(current_hp - damages, 0)
	

# Fonction d'attaque d'une unité
func attack(target: Unites) -> void:	
	target.get_damage(damage)
