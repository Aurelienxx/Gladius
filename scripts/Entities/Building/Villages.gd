extends Building
class_name Villages
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
	super.upgrade()
	level_bonus()

func level_bonus():
	match lv:
		1:
			Economy_Manager.change_money_gain(0,10)
		2:
			Economy_Manager.change_money_gain(10,3)
			damage += 5
			attack_range += 3
		3:
			Economy_Manager.change_money_gain(13,2)
			damage += 10
			attack_range += 5
