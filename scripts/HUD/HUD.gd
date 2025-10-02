extends CanvasLayer


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
