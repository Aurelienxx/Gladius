extends Button

@export var unite_Display:CharacterBody2D
@export var name_Label:Label
@export var cost_Label:Label
@export var health_Label:Label
@export var maintenance_Label:Label
@export var damage_Label:Label
@export var attack_Range_Label:Label
@export var move_Range_Label:Label
@export var thumbnail_texture:TextureRect

func _ready():
	"""
	Initialise l’affichage du bouton avec les infos de l’unité :
	nom, coût, points de vie, entretien, dégâts, portées et sprite de l'unité.
	"""
	if unite_Display:
		name_Label.text = unite_Display.name_Unite
		cost_Label.text = str(unite_Display.cost)
		health_Label.text = str(unite_Display.max_hp)
		maintenance_Label.text = str(unite_Display.maintenance)
		damage_Label.text = str(unite_Display.damage)
		attack_Range_Label.text = str(unite_Display.attack_range)
		move_Range_Label.text = str(unite_Display.move_range)
		thumbnail_texture.texture = unite_Display.thumbnail
