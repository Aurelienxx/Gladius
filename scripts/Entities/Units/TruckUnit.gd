class_name TruckUnit
extends CharacterBody2D

# Stats de base (communes à toutes les unités de ce type)
@onready var MaskOverlay : AnimatedSprite2D = $MaskSprite # Mask de couleur de l'équipe
@onready var anim:AnimatedSprite2D = $UnitSprite # Sprite de l'unité
@onready var health_bar: ProgressBar = $HealthBar

@export var cost: int = 60
@export var maintenance: int = 3
@export var max_hp: int = 150
@export var damage: int = 30
@export var move_range: int = 10
@export var attack_range: int = 3  
@export var movement: bool = false
@export var attack: bool = false
@export var name_Unite: String = "Truck"
@export var thumbnail: Texture2D

var hit_flash_timer: Timer
var base_modulate: Color

# État de l’unité (spécifique à chaque instance)
var current_hp: int
var equipe: int

func setup(_equipe: int) -> void:
	"""
	Configure l’équipe, les PV de départ et la barre de vie.
	Inverse le sprite si nécessaire et applique la couleur d’équipe.
	"""
	equipe = _equipe
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	
	if equipe == 2:
		anim.flip_h = true
		MaskOverlay.flip_h = true
		
	
	_apply_color()  

func _ready():
	"""
	Initialisation au chargement : couleur, timer de flash et couleur de base.
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
	Met à jour la barre de vie et lance l’effet de flash sur le sprite.
	"""
	health_bar.value = current_hp
	anim.modulate = Color(2,2,2,1)
	hit_flash_timer.start()

	

func _on_hit_flash_end() -> void:
	"""
	Restaure la couleur d’origine après le flash.
	"""
	anim.modulate = base_modulate

func _apply_color() -> void:
	"""
	Applique une couleur selon l’équipe : bleu (1) ou rouge (2).
	"""
	var color:Color = Color("white")
	if equipe == 1:
		color = Color("Blue")
	else:
		color = Color("red")
	MaskOverlay.modulate = color
