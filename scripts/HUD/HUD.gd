extends CanvasLayer

@export var displayGold :Label
@export var displayGainOrLoss :Label

func _ready() -> void:
	GlobalSignal.current_Money_Amount.connect(_update_Current_Money_Displayed)
	GlobalSignal.current_Money_Gain_Or_Loss.connect(_update_Current_Gain_Or_Loss)

func _update_Current_Money_Displayed(amount:int) -> void:
	displayGold.text = str(amount)

func _update_Current_Gain_Or_Loss(amount: int) -> void:
	displayGainOrLoss.text = str(amount)
	
	var textColor:Color = Color("White")
	
	if amount > 0:
		textColor = Color("00960d")
	elif amount < 0:
		textColor = Color("Red")

	displayGainOrLoss.add_theme_color_override("font_color", textColor)
	
func _on_button_button_down() -> void:
	# 'next turn' button is pressed 
	GlobalSignal.Next_Turn_Pressed.emit()


func _on_infantry_display_pressed() -> void:
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/InfantryDisplay.name_Label.text
	var appel = get_node("..")
	appel.spawnUnit(unit)
	
func _on_truck_display_pressed() -> void:
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/TruckDisplay.name_Label.text
	var appel = get_node("..")
	appel.spawnUnit(unit)
	
func _on_artillery_display_pressed() -> void:
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/ArtilleryDisplay.name_Label.text
	var appel = get_node("..")
	appel.spawnUnit(unit)
	
func _on_tank_display_pressed() -> void:
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/TankDisplay.name_Label.text
	var appel = get_node("..")
	appel.spawnUnit(unit)
