class_name InfentryUnit
extends CharacterBody2D

# Stats de base (communes à toutes les unités de ce type)

@onready var health_bar: ProgressBar = $HealthBar
@onready var MaskOverlay : AnimatedSprite2D = $MaskSprite # Mask de couleur de l'équipe
@onready var anim:AnimatedSprite2D = $UnitSprite # Sprite de l'unité

@onready var Movement: Node = $MovementManager

@export var cost: int = 15
@export var maintenance: int = 2
@export var max_hp: int = 85
@export var damage: int = 30
@export var move_range: int = 4
@export var attack_range: int = 2  
@export var movement: bool = false
@export var attack: bool = false
@export var name_Unite: String = "Infanterie"
@export var thumbnail: Texture2D

# État de l’unité (spécifique à chaque instance)
var current_hp: int
var equipe: int

func setup(_equipe: int) -> void:
	equipe = _equipe
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

	if equipe == 2:
		anim.flip_h = true
		MaskOverlay.flip_h = true

	# On confie la couleur et les animations au MovementManager
	Movement._apply_color(equipe)

func _ready():
	"""
	Initialisation au chargement : couleur, timer de flash et couleur de base.
	"""
	Movement.init(self, health_bar, anim, MaskOverlay)

func update_health_bar() -> void:
	"""
	Appelle la fonction du MovementManager pour mettre à jour la barre de vie.
	"""
	Movement.update_health_bar(current_hp, max_hp)
