extends CharacterBody2D

@onready var couleur : PointLight2D = $AnimatedSprite2D/PointLight2D
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
<<<<<<< Updated upstream

# Statistiques et attributs de base du QG
=======
@onready var upgradeHUD: Control = $UpgradeHUD
>>>>>>> Stashed changes
var max_hp: int = 1000
var lv: int = 1
var damage: int = 15
var attack_range: int = 30
var hp: int = 1000
var size_x: int = 3
var size_y: int = 3

<<<<<<< Updated upstream
# Différents niveaux du QG
var HQ1 = {"name":"QG","damage":15,"gain":15,"lv":1}
var HQ2 = {"name":"QG","damage":15,"cost":125,"gain":25,"lv":2}
var HQ3 = {"name":"QG","damage":15,"cost":150,"gain":30,"lv":3,"bonus":"Gaz Moutarde"}
=======
var HQ1Data = {"name":"QG Niveau 1", "damage":15, "goldGen" : 15, "prix": 0, "lvl":1, "Sprite" : "res://assets/sprites/EntitySprite/Units/SpriteTank/Tank1.png"}
var HQ2Data = {"name":"QG Niveau 2", "damage":20, "goldGen" : 30, "prix": 150, "lvl":2, "Sprite" : "res://assets/sprites/EntitySprite/Units/SpriteTank/Tank1.png"}
var HQ3Data = {"name":"QG Niveau 3", "damage":30, "goldGen" : 50, "prix": 275, "lvl":3, "bonus":"Gaz Moutarde", "Sprite" : "res://assets/sprites/EntitySprite/Units/SpriteTank/Tank1.png"}
>>>>>>> Stashed changes

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
	if not couleur:
		return

	if equipe == 1:
		couleur.color = Color(0, 0, 1, 0.75)
	elif equipe == 2:
		couleur.color = Color(1, 0, 0, 0.75)

func upgrade() -> void:
	"""
	Augmente le niveau du QG et applique les bonus correspondants.
	"""
	lv += 1
	apply_level_bonus()
	
func onHQClicked(unit):
	GlobalSignal.showCards.emit(self)

func apply_level_bonus() -> void:
	"""
	Applique les bonus selon le niveau actuel du QG :
	- Modifie les gains et dégâts.
	- Étend la portée d’attaque à certains niveaux.
	"""
	match lv:
		1:
<<<<<<< Updated upstream
			current_gain =  HQ1.gain
			damage = HQ1.damage
		2:
			current_gain =  HQ2.gain
			damage += 5
			attack_range += 3
		3:
			current_gain =  HQ3.gain
	
	if equipe==1:
		EconomyManager.money_gain1 = EconomyManager.change_money_gain(EconomyManager.money_gain1, EconomyManager.money_loss1, current_gain)
	elif equipe==2 : 
		EconomyManager.money_gain2 = EconomyManager.change_money_gain(EconomyManager.money_gain2, EconomyManager.money_loss2, current_gain)
		
=======
			current_gain = EconomyManager.change_money_gain(current_gain, HQ1Data.goldGen)
			damage = HQ1Data.damage
		2:
			current_gain = EconomyManager.change_money_gain(current_gain, HQ2Data.goldGen)
			damage += 5
			attack_range += 3
		3:
			current_gain = EconomyManager.change_money_gain(current_gain, HQ3Data.goldGen)
>>>>>>> Stashed changes
