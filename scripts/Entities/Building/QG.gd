extends CharacterBody2D

@onready var couleur : PointLight2D = $AnimatedSprite2D/PointLight2D
var max_hp: int = 1000
var lv: int = 1
var damage: int = 15
var attack_range: int = 30
var hp: int = 1000
var size_x: int = 3
var size_y: int = 3

var HQ1 = {"name":"QG","damage":15,"gain":15,"lv":1}
var HQ2 = {"name":"QG","damage":15,"cost":125,"gain":25,"lv":2}
var HQ3 = {"name":"QG","damage":15,"cost":150,"gain":30,"lv":3,"bonus":"Gaz Moutarde"}

var current_gain: int = 0
var current_hp: int
var equipe: int
var is_selected := false
var attack := true

func setup(_equipe: int) -> void:
	equipe = _equipe
	current_hp = max_hp
	_apply_color()


func _ready():
	_apply_color() 


func _apply_color() -> void:
	if not couleur:
		return

	if equipe == 1:
		couleur.color = Color(0, 0, 1, 0.75)
	elif equipe == 2:
		couleur.color = Color(1, 0, 0, 0.75)

func upgrade():
	lv += 1
	apply_level_bonus()

func apply_level_bonus():
	match lv:
		1:
			current_gain = EconomyManager.change_money_gain(current_gain, HQ1.gain)
			damage = HQ1.damage
		2:
			current_gain = EconomyManager.change_money_gain(current_gain, HQ2.gain)
			damage += 5
			attack_range += 3
		3:
			current_gain = EconomyManager.change_money_gain(current_gain, HQ3.gain)
