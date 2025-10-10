extends CharacterBody2D

@onready var flag: AnimatedSprite2D=$FlagSprite
@onready var anim: AnimatedSprite2D = $BuildingSprite
@onready var health_bar: ProgressBar = $HealthBar

const buildingName = "Village"

# Statistiques et attributs de base du village
var lv: int = 1
var max_hp: int = 200
var attack: int = 20
var attack_range: int = 10
var size_x: int = 3
var size_y: int = 3
var upgrade_cost: int = 60

# Différents niveaux du village
var Vlg1 = {"name": "Village", "gain": 10, "lv": 1}
var Vlg2 = {"name": "Village", "cost": 65, "gain": 13, "lv": 2}
var Vlg3 = {"name": "Village", "attack": 15, "cost": 80, "gain": 15, "lv": 3}

# Variables d’état
var current_gain: int = 0
var current_hp: int
var current_lv: int = 1
var zone_enabled: bool = false
var zone_radius: int = 0
var equipe: int = 0

const EQUIPE_NEUTRAL = 0
const EQUIPE_ONE = 1
const EQUIPE_TWO = 2

# Effet de clignotement à la réception de dégâts
var hit_flash_timer: Timer
var base_modulate: Color

func setup(_equipe: int) -> void:
	"""
	Initialise le QG selon l’équipe à laquelle il appartient.
	:param _equipe: (int) Numéro de l’équipe (1 ou 2).
	:return: None
	"""
	GlobalSignal.unit_finished_moving.connect(check_nearby_units_for_capture)
	
	equipe = _equipe
	current_hp = max_hp
	_apply_color()
	flag.play()
	anim.play()
	
func _ready() -> void:
	"""
	Prépare les composants du QG au lancement de la scène :
	- Applique la couleur d’équipe.
	- Configure le timer du clignotement lors des dégâts.
	"""
	add_to_group("Village")
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_apply_color()

	# Préparation du timer de clignotement
	hit_flash_timer = Timer.new()
	hit_flash_timer.wait_time = 0.2
	hit_flash_timer.one_shot = true
	add_child(hit_flash_timer)
	hit_flash_timer.timeout.connect(_on_hit_flash_end)

	base_modulate = anim.modulate

func _update_health_bar() -> void: 
	health_bar.value = current_hp 

func take_damage(dmg:int) -> void:
	"""
	Met à jour la barre de vie et déclenche l’animation de clignotement du QG.
	"""
	current_hp -= dmg
	health_bar.value = current_hp 
	anim.modulate = Color(2, 2, 2, 1)
	hit_flash_timer.start()

func _on_hit_flash_end() -> void:
	"""
	Remet la couleur normale après le clignotement.
	"""
	anim.modulate = base_modulate
	
func upgrade():
	"""
	Augmente le niveau du QG et applique les bonus correspondants.
	"""
	lv=lv+1
	level_bonus()

func level_bonus():
	"""
	Applique les bonus selon le niveau actuel du QG :
	- Modifie les gains et dégâts.
	- Étend la portée d’attaque à certains niveaux.
	"""
	match lv:
		1:
			current_gain=10
		2:
			current_gain= 13
			attack += 5
			attack_range += 3
		3:
			current_gain= 15
			attack += 10
			attack_range += 5
	
	EconomyManager.change_money_gain(current_gain)
	
func capture():
	"""
	Permet la capture de la ville par une autre équipe :
	- Si neutre, change simplement d’équipe
	- Si occupée, elle perd de la vie avant d’être capturée
	"""
	equipe = GameState.current_player
	current_hp = max_hp 
	
	_update_health_bar()
	_apply_color()
	flag.play()
	anim.play()
	level_bonus()
	
func _apply_color():
	"""
	Change la couleur lumineuse selon l’équipe :
	- Blanc = neutre
	- Bleu = équipe 1
	- Rouge = équipe 2
	"""
	var color:Color = Color("white")
	if equipe == 1:
		color = Color("Blue")
	elif equipe == 2:
		color = Color("red")
	flag.modulate = color

func check_nearby_units_for_capture() -> void:
	if equipe != 0:
		return
	var capture_radius := 150.0 # pixels autour 
	for unit in GameState.all_units:
		if global_position.distance_to(unit.global_position) <= capture_radius:
			capture()
			break
