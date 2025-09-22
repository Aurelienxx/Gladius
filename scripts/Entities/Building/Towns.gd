extends Building
class_name Towns

var Town1 = {
	"name":"Town",
	"gain": 15,
	"lv":1,
}
var Town2 = {
	"name":"Town",
	"cost": 85,
	"gain": 18,
	"lv":2,
}
var Town3 = {
	"name":"Town",
	"attack": 15,
	"cost": 100,
	"gain": 20,
	"lv":3,
}
func _init():
	super("Towns", 1, 500, 30, 10, 9)
	
	
	
func upgrade():
	lv=lv+1
	level_bonus()
	
	
func level_bonus():
	match lv:
		1:
			Economy_Manager.change_money_gain(0,15)
		2:
			Economy_Manager.change_money_gain(15,3)
			damage += 5
			attack_range += 3
		3:
			Economy_Manager.change_money_gain(18,2)
			damage += 10
			attack_range += 5
