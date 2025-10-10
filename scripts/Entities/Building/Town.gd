extends CharacterBody2D

@onready var flag: AnimatedSprite2D=$FlagSprite
@onready var anim: AnimatedSprite2D = $BuildingSprite
@onready var health_bar: ProgressBar = $HealthBar

const buildingName = "Town"

# Statistiques et attributs de base de la ville
var lv: int = 1
var max_hp: int = 200
var attack: int = 20
var attack_range: int = 10
var size_x: int = 3
var size_y: int = 3
var upgrade_cost: int = 60

# Différents niveaux de la ville
var Town1 = {"name": "Town", "gain": 15, "lv": 1}
var Town2 = {"name": "Town", "cost": 85, "gain": 18, "lv": 2}
var Town3 = {"name": "Town", "attack": 15, "cost": 100, "gain": 20, "lv": 3}

# Variables d’état
var current_gain: int = 0
var current_hp: int
var current_lv: int = 1
var zone_enabled: bool = false
var zone_radius: int = 0
var equipe: int

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
	equipe = _equipe
	current_hp = max_hp
	_apply_color()
	flag.play()
	anim.play()

func getType():
	return "Town"

func _ready() -> void:
	"""
	Prépare les composants du QG au lancement de la scène :
	- Applique la couleur d’équipe.
	- Configure le timer du clignotement lors des dégâts.
	"""
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_apply_color()

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
	anim.modulate = Color(2, 2, 2, 1)
	hit_flash_timer.start()
	_update_health_bar()


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
			current_gain=+15
		2:
			current_gain=18
			attack += 5
			attack_range += 3
		3:
			current_gain=20
			attack += 10
			attack_range += 5
	
func capture():
	"""
	Permet la capture de la ville par une autre équipe :
	- Si neutre, change simplement d’équipe
	- Si occupée, elle perd de la vie avant d’être capturée
	"""
	
	equipe = GameState.current_player
	current_hp = max_hp # reset la vie
	
	EconomyManager.change_money_gain(current_gain)
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
