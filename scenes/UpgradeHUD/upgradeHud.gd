extends CanvasLayer

signal achatLvl2(level: int)
signal achatLvl3(level: int)

@onready var HQCard1 : Panel = $UpgradeHUD/HBoxContainer/LevelCardLv1
@onready var HQCard2 : Panel = $UpgradeHUD/HBoxContainer/LevelCardLv2
@onready var HQCard3 : Panel = $UpgradeHUD/HBoxContainer/LevelCardLv3
var container: Control

func displayCards(HQ1Data: Dictionary, HQ2Data: Dictionary, HQ3Data: Dictionary):
	updateCard(HQCard1, HQ1Data)
	updateCard(HQCard2, HQ2Data)
	updateCard(HQCard3, HQ3Data)

func updateCard(card: Panel, HQData: Dictionary):
	if not card:
		print("Erreur: card est null !")
		return
	if HQData["lvl"] == 3:
		card.get_node("Name").text = "Nom : " + HQData["name"]
		card.get_node("MarginContainer/HBoxContainer/VBoxContainer/GoldGeneration").text = "Génération d'or : " + str(HQData["gain"])
		card.get_node("MarginContainer/HBoxContainer/VBoxContainer/DMG").text = "Dégâts : " + str(HQData["damage"])
		card.get_node("MarginContainer/HBoxContainer/VBoxContainer2/Bonus").text = "Bonus : " + str(HQData["bonus"])
		card.get_node("Cost").text = "Coût : " + str(HQData["prix"])
	else:
		if card.has_node("Name"):
			card.get_node("Name").text = "Nom : %s" % HQData["name"]
		card.get_node("MarginContainer/HBoxContainer/CenterContainer2/GoldGeneration").text = "Génération d'or : " + str(HQData["gain"])
		card.get_node("MarginContainer/HBoxContainer/CenterContainer/DMG").text = "Dégâts : " + str(HQData["damage"])
		card.get_node("Cost").text = "Coût : " + str(HQData["prix"])
	card.get_node("BuildingSprite").play()
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		visible = false


func _on_button_lv_2_pressed() -> void:
	emit_signal("achatLvl2", 2)

func _on_button_lv_3_pressed() -> void:
	emit_signal("achatLvl3", 3)
