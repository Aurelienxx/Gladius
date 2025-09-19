extends Building
class_name Towns

func _init():
	super("Towns", 1, 500, 30, 10, 9)
	
	
	
	func upgrade():
	super.upgrade()
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
