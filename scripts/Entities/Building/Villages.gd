extends Building
class_name Villages
var current_gain = 0
var lv1 = {
	"name":"Village",
	"gain": 10,
	"lv":1,
}
var lv2 = {
	"name":"Village",
	"cost": 65,
	"gain": 13,
	"lv":2,
}
var lv3 = {
	"name":"Village",
	"attack": 15,
	"cost": 80,
	"gain": 15,
	"lv":3,
}
func _init():
	super("Village", 1, 1000, 30, 10, 9)

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
