extends Building
class_name HeadQuarters

var current_gain = 0
var HQ1 = {
	"name":"QG",
	"attack": 15,
	"gain": 15,
	"lv":1,
}
var HQ2 = {
	"name":"QG",
	"attack": 15,
	"cost": 125,
	"gain": 25,
	"lv":2,
}
var HQ3 = {
	"name":"QG",
	"attack": 15,
	"cost": 150,
	"gain": 30,
	"lv":3,
	"bonus":"Gaz Moutarde"
}

func _ready() : 
	print("La partie n'a pas commencé, vous gagnez ",current_gain," par tour")
	upgrade()
	print("Gain vers niveau ",lv)
	print("vous gagnez maintenant ",current_gain," par tour")
	upgrade()
	print("Gain vers niveau ",lv)
	print("vous gagnez maintenant ",current_gain," par tour")
	upgrade()
	print("Gain vers niveau ",lv)
	print("vous gagnez maintenant ",current_gain," par tour")

func _init():
	super("QG", 0, 1000, 30, 0, 0)
func upgrade():
	lv=lv+1
	level_bonus()

func level_bonus():
	match lv:
		1:
			current_gain=EconomyManager.change_money_gain(current_gain,20)

		2:
			current_gain=EconomyManager.change_money_gain(current_gain,5)
			attack += 5
			attack_range += 3
		3:
			current_gain=EconomyManager.change_money_gain(current_gain,5)
