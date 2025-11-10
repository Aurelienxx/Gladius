extends Node2D

const explosionEffect = preload("res://scenes/Map/Effects/explosions.tscn")
const gazEffect = preload("res://scenes/Map/Effects/gaz.tscn")
const spawnEffect     = preload("res://scenes/Map/Effects/spawn.tscn")

func _ready() -> void:
	GlobalSignal.attack_occured_pos.connect(play_anim_explosion)
	GlobalSignal.hq_attack_occured_pos.connect(play_anim_gaz)
	GlobalSignal.unit_spawn_pos.connect(play_anim_spawn)

#### Explosion animation 

func play_anim_explosion(explo_position:Vector2i):
	# Lance l'animation d'explosion sur l'unité attaquée
	var explosion = explosionEffect.instantiate()
	explosion.position = explo_position
	add_child(explosion)
	
#### Gaz animation 

func play_anim_gaz(gaz_position:Vector2i):
	# Lance l'animation de gaz sur la cellulle concernée
	var gaz = gazEffect.instantiate()
	gaz.position = gaz_position
	add_child(gaz)
		
#### Spawn animation

func play_anim_spawn(spawn_pos:Vector2i):
	# Lance l'animation de spawn sur l'unité qui vient d'apparaitre
	var spawn = spawnEffect.instantiate()
	spawn.position = spawn_pos
	add_child(spawn)
