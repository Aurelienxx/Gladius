extends Entities
class_name Unites

# Statistiques
var cost: int
var maintenance: int
var damage: int
var move_range: int
var attack_range: int


# Initialisation de l'entité
func _init(
	_nom: String = "Unite",
	_cost: int = 0,
	_maintenance: int = 0,
	_hp: int = 0,
	_damage: int = 0,
	_move_range: int = 0,
	_attack_range: int = 0,
	_position: Vector2 = Vector2.ZERO
):
	super(hp)
	
	cost = _cost
	maintenance = _maintenance
	hp = _hp
	damage = _damage
	move_range = _move_range
	attack_range = _attack_range


# Fonction d'attaque
func attack(target: Entities) -> void:
	target.get_damage(damage)
