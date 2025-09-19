extends Building
class_name Villages

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
