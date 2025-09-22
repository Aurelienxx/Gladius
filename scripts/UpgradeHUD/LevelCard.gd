extends Panel

@onready var buttons: Button = $Button

var money = 50.0

func showCard(name: String, hp: int, dmg: int, gold_generation: int, cost: int, level: int, range: int, bonus: String):
	
