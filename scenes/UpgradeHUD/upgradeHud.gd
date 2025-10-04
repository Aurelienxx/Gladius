extends Control

@onready var HQCard1 : Panel = $"HBoxContainer/LevelCardLv1"
@onready var HQCard2 : Panel = $"HBoxContainer/LevelCardLv2"
@onready var HQCard3 : Panel = $"HBoxContainer/LevelCardLv3"

func _ready():
	visible = false
	GlobalSignal.showCards.connect(displayCards)
	visible = true

func displayCards(Building):
	"""
	Affiche les infos du bâtiment dans la carte d’aperçu.
	:param buildingName: (String) Nom du bâtiment.
	:param pv: (int) Points de vie max.
	:param degats: (int) Dégâts infligés.
	:param _attack_range: (int) Portée d’attaque.
	:param gold_generation: (int) Production d’or par tour.
	:param cost: (int) Coût de construction.
	:param _bon: (String) Bonus conféré.
	:param SpritePath: (String) Chemin du sprite à charger.
	:return: None
	"""
	
	visible = true
	updateCard(HQCard1, Building.HQ1Data)
	updateCard(HQCard2, Building.HQ2Data)
	updateCard(HQCard3, Building.HQ3Data)

func updateCard(card: Panel, HQData: Dictionary):
	if HQData["lvl"] == 3:
		card.get_node("Name").text = "Nom : " + HQData["name"]
		card.get_node("MarginContainer/HBoxContainer/VBoxContainer/GoldGeneration").text = "Génération d'or : " + str(HQData["goldGen"])
		card.get_node("MarginContainer/HBoxContainer/VBoxContainer/DMG").text = "Dégâts : " + str(HQData["damage"])
		card.get_node("MarginContainer/HBoxContainer/VBoxContainer2/Bonus").text = "Bonus : " + str(HQData["bonus"])
		card.get_node("Cost").text = "Coût : " + str(HQData["prix"])
		card.get_node("BuildingSprite").texture = load(HQData["Sprite"])
	else:
		card.get_node("Name").text = "Nom : " + HQData["name"]
		card.get_node("MarginContainer/HBoxContainer/CenterContainer2/GoldGeneration").text = "Génération d'or : " + str(HQData["goldGen"])
		card.get_node("MarginContainer/HBoxContainer/CenterContainer/DMG").text = "Dégâts : " + str(HQData["damage"])
		card.get_node("Cost").text = "Coût : " + str(HQData["prix"])
		card.get_node("BuildingSprite").texture = load(HQData["Sprite"])

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		visible = false
