extends Panel

@onready var buttons: Button = $Button

var money = 50.0

func _on_button_pressed() -> void:
	if money >= this.price:
		print("yes")

func create_card()
