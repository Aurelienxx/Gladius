extends CanvasLayer

@export var displayGold :Label
@export var displayGainOrLoss :Label

func _ready() -> void:
	"""
	Connecte les signaux globaux de gestion d’argent aux fonctions locales d’affichage.
	"""
	GlobalSignal.current_Money_Amount.connect(_update_Current_Money_Displayed)
	GlobalSignal.current_Money_Gain_Or_Loss.connect(_update_Current_Gain_Or_Loss)

func _update_Current_Money_Displayed(amount:int) -> void:
	"""
	Met à jour le texte affichant le montant actuel d’argent.

	:param amount: (int) Montant actuel à afficher.
	"""
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
	"""
	Émet un signal global lorsque le bouton "Next Turn" est pressé.
	"""
	GlobalSignal.Next_Turn_Pressed.emit()


func _on_infantry_display_pressed() -> void:
	"""
	Construit une unité d’infanterie via le menu de construction.
	"""
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/InfantryDisplay.unite_Display
	GlobalSignal.spawn_Unit.emit(unit)
	

func _on_truck_display_pressed() -> void:
	"""
	Construit une unité de camion via le menu de construction.
	"""
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/TruckDisplay.unite_Display
	GlobalSignal.spawn_Unit.emit(unit)
	
func _on_artillery_display_pressed() -> void:
	"""
	Construit une unité d’artillerie via le menu de construction.
	"""
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/ArtilleryDisplay.unite_Display
	GlobalSignal.spawn_Unit.emit(unit)
	
func _on_tank_display_pressed() -> void:
	"""
	Construit une unité de tank via le menu de construction.
	"""
	var unit = $MenuDisplay/VBoxContainer/MarginContainer/ContructionMenu/ConstructionDisplay/TankDisplay.unite_Display
	GlobalSignal.spawn_Unit.emit(unit)
