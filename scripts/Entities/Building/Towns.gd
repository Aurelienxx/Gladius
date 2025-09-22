extends Building
class_name Towns
var current_gain =0
var lv1 = {
	"name":"Town",
	"gain": 15,
	"lv":1,
}
var lv2 = {
	"name":"Town",
	"cost": 85,
	"gain": 18,
	"lv":2,
}
var lv3 = {
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
			current_gain=EconomyManager.change_money_gain(current_gain,15)
		2:
			current_gain=EconomyManager.change_money_gain(current_gain,18)
			attack += 5
			attack_range += 3
		3:
			current_gain=EconomyManager.change_money_gain(current_gain,20)
			attack += 10
			attack_range += 5
