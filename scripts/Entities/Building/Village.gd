extends CharacterBody2D

@onready var couleur:PointLight2D=$AnimatedSprite2D/PointLight2D
var current_gain = 0
var Vlg1 = {
	"name":"Village",
	"gain": 10,
	"lv":1,
}
var Vlg2 = {
	"name":"Village",
	"cost": 65,
	"gain": 13,
	"lv":2,
}
var Vlg3 = {
	"name":"Village",
	"attack": 15,
	"cost": 80,
	"gain": 15,
	"lv":3,
}

var lv: int =1
var hp: int =200
var attack: int = 20
var attack_range: int = 10
var size_x: int = 3
var size_y: int = 3
var upgrade_cost: int = 60
#variable dynamique
var current_lv: int =1
var zone_enabled : bool=false
var zone_radius : int= 0
	
	
func upgrade():
	lv=lv+1
	level_bonus()

func level_bonus():
	match lv:
		1:
			current_gain=EconomyManager.change_money_gain(current_gain,10)
		2:
			current_gain=EconomyManager.change_money_gain(current_gain,13)
			attack += 5
			attack_range += 3
		3:
			current_gain=EconomyManager.change_money_gain(current_gain,15)
			attack += 10
			attack_range += 5
	
	
	
