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


const TEAM_NEUTRAL = 0
const TEAM_ONE = 1
const TEAM_TWO = 2
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
var team: int =0
	
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
	
	
func capture(nb: int):
	if nb == team:
		return # déjà capturé par cette équipe

	match team:
		TEAM_NEUTRAL:
			team = nb
			_apply_color(nb)

		TEAM_ONE, TEAM_TWO:
			if nb != team:
				hp -= 50 # par exemple, attaque pour capturer
				if hp <= 0:
					team = nb
					hp = 200 # reset la vie
					_apply_color(nb)
			
func _apply_color(new_team: int):
	if team ==0:
		couleur.color=Color(1,1,1,1) 
	if team == 1:
		couleur.color = Color(0, 0, 1, 1.0)
	elif team == 2:
		couleur.color = Color(1, 0.0, 0.0, 1.0)



	
