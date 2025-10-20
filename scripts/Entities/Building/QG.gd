extends CharacterBody2D

@onready var upgradeHUD : CanvasLayer = $UpgradeHUD

@onready var flag: AnimatedSprite2D=$FlagSprite
@onready var anim: AnimatedSprite2D = $BuildingSprite

@onready var health_bar: ProgressBar = $HealthBar

const buildingName = "HQ"

var current_player: int
# Statistiques et attributs de base du QG
var max_hp: int = 1000
var damage: int
var attack_range: int

var lv: int = 1
var size_x: int = 3
var size_y: int = 3

# Différents niveaux du QG
var HQ1Data = {"name":"QG Niveau 1", "damage":15, "gain" : 15, "prix": 0, "lvl":1, "Sprite" : "res://assets/sprites/EntitySprite/Buildings/HQ/HQ_sketch.png"}
var HQ2Data = {"name":"QG Niveau 2", "damage":20, "gain" : 30, "prix": 150, "lvl":2, "Sprite" : "res://assets/sprites/EntitySprite/Buildings/HQ/HQ_sketch.png"}
var HQ3Data = {"name":"QG Niveau 3", "damage":30, "gain" : 50, "prix": 275, "lvl":3, "bonus":"Gaz Moutarde", "Sprite" : "res://assets/sprites/EntitySprite/Buildings/HQ/HQ_sketch.png"}

# Variables d’état
var current_gain: int = 0
var current_hp: int
var equipe: int
var is_selected := false
var attack := true

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
	upgradeHUD.achatLvl2.connect(upgradeLvl2Signal)
	upgradeHUD.achatLvl3.connect(upgradeLvl3Signal)
	anim.play("Level1")
	flag.play()
	
func upgradeLvl2Signal(lvl: int):
	upgrade(lvl)

func upgradeLvl3Signal(lvl: int):
	upgrade(lvl)

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
			upgradeHUD.get_node("UpgradeHUD/HBoxContainer/LevelCardLv2/ButtonLv2").queue_free()
					
	else:
		if EconomyManager.money_check(HQ3Data["prix"]):
			EconomyManager.buy_something(HQ3Data["prix"])
			lv += 1
			apply_level_bonus()
			upgradeHUD.get_node("UpgradeHUD/HBoxContainer/LevelCardLv2/ButtonLv2").queue_free()
			
func apply_level_bonus() -> void:
	"""
	Applique les bonus selon le niveau actuel du QG :
	- Modifie les gains et dégâts.
	- Étend la portée d’attaque à certains niveaux.
	"""
	match lv:
		1:
			current_gain =  HQ1Data["gain"]
			damage = HQ1Data["damage"]
			anim.play("Level1")
		2:
			current_gain =  HQ2Data["gain"]
			damage += 5
			attack_range += 3
			anim.play("Level2")
		3:
			current_gain =  HQ3Data["gain"]
			anim.play("Level3")
	
	if equipe == GameState.current_player:
		EconomyManager.change_money_gain(current_gain)
	
func showUpgradeHUD(equipe: int):
	current_player = equipe
	upgradeHUD.displayCards(HQ1Data, HQ2Data, HQ3Data)
	upgradeHUD.visible = true
	
	
