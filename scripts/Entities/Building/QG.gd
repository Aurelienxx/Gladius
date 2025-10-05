extends CharacterBody2D

@onready var upgradeHUD : CanvasLayer = $UpgradeHUD

@onready var flag: AnimatedSprite2D=$FlagSprite
@onready var anim: AnimatedSprite2D = $BuildingSprite

@onready var health_bar: ProgressBar = $HealthBar

var current_player: int
# Statistiques et attributs de base du QG
var max_hp: int = 1000
var lv: int = 1
var damage: int = 15
var attack_range: int = 5
var hp: int = 1000
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

func getTeam():
	return equipe

func getType():
	return "QG"
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

func update_health_bar() -> void:
	"""
	Met à jour la barre de vie et déclenche l’animation de clignotement du QG.
	"""
	health_bar.value = current_hp
	anim.modulate = Color(2,2,2,1)
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
		match current_player:
			1:
				if EconomyManager.current_money1 >= HQ2Data["prix"]:
					EconomyManager.current_money1 = EconomyManager.buy_something(EconomyManager.current_money1, HQ2Data["prix"])
					lv += 1
					apply_level_bonus()
					upgradeHUD.get_node("UpgradeHUD/HBoxContainer/LevelCardLv2/ButtonLv2").queue_free()
			2:
				if EconomyManager.current_money2 >= HQ2Data["prix"]:
					EconomyManager.current_money2 = EconomyManager.buy_something(EconomyManager.current_money2, HQ2Data["prix"])
					lv += 1
					apply_level_bonus()
					upgradeHUD.get_node("UpgradeHUD/HBoxContainer/LevelCardLv2/ButtonLv2").queue_free()
	else:
		match current_player:
			1:
				if EconomyManager.current_money1 >= HQ3Data["prix"]:
					EconomyManager.buy_something(EconomyManager.current_money1, HQ3Data["prix"])
					lv += 1
					apply_level_bonus()
					upgradeHUD.get_node("UpgradeHUD/HBoxContainer/LevelCardLv3/ButtonLv3").queue_free()
			2:
				if EconomyManager.current_money2 >= HQ3Data["prix"]:
					EconomyManager.buy_something(EconomyManager.current_money2, HQ3Data["prix"])
					lv += 1
					apply_level_bonus()
					upgradeHUD.get_node("UpgradeHUD/HBoxContainer/LevelCardLv3/ButtonLv3").queue_free()

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
	
	flag.frame = 0
	if equipe==1:
		EconomyManager.money_gain1 = EconomyManager.change_money_gain(EconomyManager.money_gain1, EconomyManager.money_loss1, current_gain)
	elif equipe==2 : 
		EconomyManager.money_gain2 = EconomyManager.change_money_gain(EconomyManager.money_gain2, EconomyManager.money_loss2, current_gain)

func showUpgradeHUD(equipe: int):
	current_player = equipe
	upgradeHUD.displayCards(HQ1Data, HQ2Data, HQ3Data)
	upgradeHUD.visible = true
	
	
