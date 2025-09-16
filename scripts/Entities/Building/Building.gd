extends Node2D

class_name Building

# --- Statistiques  ---
var nom : String
var lv:int
var hp: int
var damage: int
var attack_range: int
var size: Vector2i
var upgrade_cost: int

# Variable dynamique
var current_hp: int
var current_lv

func _init(
		_name: String = "Building",
		_upgrade_cost: int = 0,
		_lv:int=1,
		_hp: int = 0,
		_damage: int = 0,
		_attack_range: int = 10,
		_size: Vector2i = Vector2i(3,3)
	):
	name = _name
	upgrade_cost = _upgrade_cost
	lv = _lv
	hp = _hp
	current_hp = _hp
	current_lv=_lv
	damage = _damage
	attack_range = _attack_range
	

# Fonction de réception des dégâts
func get_damage(damages: int) -> void:
	current_hp = max(current_hp - damages,0)
	

# Fonction d'attaque d'une Building
func attack(target: Unites) -> void:	
	target.get_damage(damage)
	

	

	
