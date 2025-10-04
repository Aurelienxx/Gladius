extends CharacterBody2D

@onready var couleur: PointLight2D=$AnimatedSprite2D/PointLight2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var Vlg1 = {"name": "Village", "gain": 10, "lv": 1}
var Vlg2 = {"name": "Village", "cost": 65, "gain": 13, "lv": 2}
var Vlg3 = {"name": "Village", "attack": 15, "cost": 80, "gain": 15, "lv": 3}

const EQUIPE_NEUTRAL = 0
const EQUIPE_ONE = 1
const EQUIPE_TWO = 2

var lv: int = 1
var max_hp: int = 200
var attack: int = 20
var attack_range: int = 10
var size_x: int = 3
var size_y: int = 3
var upgrade_cost: int = 60

var current_gain: int = 0
var current_hp: int
var current_lv: int = 1
var zone_enabled: bool = false
var zone_radius: int = 0
var equipe: int = 0

var hit_flash_timer: Timer
var base_modulate: Color

func _ready() -> void:
	add_to_group("Village")
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_apply_color(equipe)

	# Préparation du timer de clignotement
	hit_flash_timer = Timer.new()
	hit_flash_timer.wait_time = 0.2
	hit_flash_timer.one_shot = true
	add_child(hit_flash_timer)
	hit_flash_timer.timeout.connect(_on_hit_flash_end)

	base_modulate = anim.modulate


func setup(_equipe: int) -> void:
	equipe = _equipe
	current_hp = max_hp
	_apply_color(equipe)


func update_health_bar() -> void:
	"""
	Met à jour la barre de vie et déclenche le flash visuel.
	"""
	health_bar.value = current_hp
	anim.modulate = Color(2, 2, 2, 1)
	hit_flash_timer.start()


func _on_hit_flash_end() -> void:
	"""
	Remet la couleur normale après le clignotement.
	"""
	anim.modulate = base_modulate
	
	
func upgrade():
	lv=lv+1
	level_bonus()

func level_bonus():
	match lv:
		1:
			current_gain=EconomyManager.change_money_gain(current_gain,10)
		2:
			current_gain=EconomyManager.change_money_gain(current_gain,13)
			attack += 5
			attack_range += 3
		3:
			current_gain=EconomyManager.change_money_gain(current_gain,15)
			attack += 10
			attack_range += 5
	
	
func capture(nb: int):
	if nb == equipe:
		return # déjà capturé par cette équipe

	match equipe:
		0: # neutre
			equipe = nb
			_apply_color(nb)
		1, 2:
			if nb != equipe:
				max_hp -= 50
				if max_hp <= 0:
					equipe = nb
					max_hp = 200 # reset la vie
					_apply_color(nb)

		EQUIPE_ONE, EQUIPE_TWO:
			if nb != equipe:
				max_hp -= 50 # par exemple, attaque pour capturer
				if max_hp <= 0:
					equipe = nb
					max_hp = 200 # reset la vie
					_apply_color(nb)
			
func _apply_color(new_equipe: int):
	if equipe ==0:
		couleur.color=Color(1,1,1,1) 
	if equipe == 1:
		couleur.color = Color(0, 0, 1, 1.0)
	elif equipe == 2:
		couleur.color = Color(1, 0.0, 0.0, 1.0)



	
