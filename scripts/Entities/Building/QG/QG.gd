extends CharacterBody2D

@onready var upgradeHUD : CanvasLayer = $UpgradeHUD

@onready var flag: AnimatedSprite2D=$FlagSprite
@onready var anim: AnimatedSprite2D = $BuildingSprite

@onready var health_bar: ProgressBar = $HealthBar

const buildingName = "QG"

var current_player: int 
# Statistiques et attributs de base du QG
var max_hp: int = 500
var damage: int
var attack_range: int
var isAI : bool = false
var bonus : String

var lv: int = 1
var size_x: int = 3
var size_y: int = 3

# Différents niveaux du QG
var HQ1Data = {"name":"QG Niveau 1", "max_hp": 500 ,"damage":0, "attack_range": 0, "gain" : 15, "prix": 0, "lvl":1, "bonus":"", "Sprite" : "res://assets/sprites/EntitySprite/Buildings/HQ/Level_1/HQ_Level_1_1.png"}
var HQ2Data = {"name":"QG Niveau 2", "max_hp": 750, "damage":0, "attack_range": 0, "gain" : 30, "prix": 150, "lvl":2, "bonus":"", "Sprite" : "res://assets/sprites/EntitySprite/Buildings/HQ/Level_2/HQ_Level_2_1.png"}
var HQ3Data = {"name":"QG Niveau 3", "max_hp": 1000, "damage":15, "attack_range": 5, "gain" : 50, "prix": 275, "lvl":3, "bonus":"Gaz Moutarde", "Sprite" : "res://assets/sprites/EntitySprite/Buildings/HQ/Level_3/HQ_Level_3_1.png"}

# Variables d’état
var current_gain: int = 0
var current_hp: int
var equipe: int
var is_selected := false
var attack := true

# Effet de clignotement à la réception de dégâts
var hit_flash_timer: Timer
var base_modulate: Color

var current_real_position

func setup(_equipe: int) -> void:
	"""
	Initialise le QG selon l’équipe à laquelle il appartient.
	:param _equipe: (int) Numéro de l’équipe (1 ou 2).
	:return: None
	"""
	current_real_position = self.global_position
	
	current_hp = max_hp
	equipe = _equipe
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	_apply_color()
	apply_level_bonus()

func _ready():
	"""
	Prépare les composants du QG au lancement de la scène :
	- Applique la couleur d’équipe.
	- Configure le timer du clignotement lors des dégâts.
	"""
	_apply_color() 
	hit_flash_timer = Timer.new()
	hit_flash_timer.wait_time = 0.2
	hit_flash_timer.one_shot = true
	add_child(hit_flash_timer)
	hit_flash_timer.timeout.connect(_on_hit_flash_end)

	base_modulate = anim.modulate
	upgradeHUD.visible = false
	anim.play("Level1")
	flag.play()

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
	Remet la couleur normale du QG après le clignotement.
	"""
	anim.modulate = base_modulate


func _apply_color() -> void:
	"""
	Applique une couleur de lumière différente selon l’équipe.
	Équipe 1 : Bleu / Équipe 2 : Rouge
	"""
	var color:Color = Color("white")
	if equipe == 1:
		color = Color("Blue")
	elif equipe == 2:
		color = Color("red")
	flag.modulate = color
	
func upgrade(lvl: int) -> void:
	"""
	Augmente le niveau du QG et applique les bonus correspondants.
	"""

	if lvl == 2:
		if EconomyManager.money_check(HQ2Data["prix"]):
			EconomyManager.buy_something(HQ2Data["prix"])
			lv += 1
			apply_level_bonus()
			upgradeHUD.hideBuyButton(2)
		flag.stop()
		flag.play()
	else:
		if getLevel() == 2:
			if EconomyManager.money_check(HQ3Data["prix"]):
				EconomyManager.buy_something(HQ3Data["prix"])
				lv += 1
				apply_level_bonus()
				upgradeHUD.hideBuyButton(3)
		flag.stop()
		flag.play()

func apply_level_bonus() -> void:
	"""
	Applique les bonus selon le niveau actuel du QG :
	- Modifie les gains et dégâts.
	- Étend la portée d’attaque à certains niveaux.
	"""
	match lv:
		1:
			max_hp = HQ1Data["max_hp"]
			damage = HQ1Data["damage"]
			attack_range = HQ1Data["attack_range"]
			current_gain =  HQ1Data["gain"]
			anim.play("Level1")
		2:
			health_bar.max_value = HQ2Data["max_hp"]
			current_hp += (HQ2Data["max_hp"] - HQ1Data["max_hp"])
			health_bar.value = current_hp
			damage = HQ2Data["damage"]
			attack_range = HQ2Data["attack_range"]
			current_gain =  HQ2Data["gain"]
			anim.play("Level2")
		3:
			health_bar.max_value = HQ3Data["max_hp"]
			current_hp += (HQ3Data["max_hp"] - HQ2Data["max_hp"])
			health_bar.value = current_hp
			damage = HQ3Data["damage"]
			attack_range = HQ3Data["attack_range"]
			current_gain =  HQ3Data["gain"]
			anim.play("Level3")
	
	flag.play()
	if equipe == GameState.current_player:
		EconomyManager.change_money_gain(current_gain)
	
func showUpgradeHUD(team: int):
	current_player = team
	upgradeHUD.displayCards(HQ1Data, HQ2Data, HQ3Data)
	upgradeHUD.visible = true

func getName():
	return buildingName

func getEquipe():
	return equipe

func getLevel():
	return lv
