extends Building
class_name HeadQuarters

var current_gain = 0
var current_money = 500


func _ready() : 
	print("La partie n'a pas commencé, vous gagnez ",current_gain," par tour")
	upgrade()
	print("Gain vers niveau ",lv)
	print("vous gagnez maintenant ",current_gain," par tour")
	print()
	
	current_money = EconomyManager.buy_something(current_money,125)
	print("Achat d'une amélioration! Vous possédez maintenant ", current_money, " argent")
	upgrade()
	print("Gain vers niveau ",lv)
	print("vous gagnez maintenant ",current_gain," par tour")
	print()
	
	current_money = EconomyManager.buy_something(current_money,150)
	print("Achat d'une amélioration! Vous possédez maintenant ", current_money, " argent")
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
