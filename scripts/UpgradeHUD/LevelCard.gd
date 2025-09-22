extends Panel

@onready var nom: Label = $Name
@onready var hp: Label = $HBoxContainer/VBoxContainer/HP
@onready var dmg: Label = $HBoxContainer/VBoxContainer/DMG
@onready var portee: Label = $HBoxContainer/VBoxContainer/Range
@onready var goldGen: Label = $HBoxContainer/VBoxContainer2/GoldGeneration
@onready var bonus: Label = $HBoxContainer/VBoxContainer2/Bonus
@onready var buildingSprite: Panel = $BuildingSprite
@onready var priceCost: Label = $Cost

func showCard(buildingName: String, pv: int, degats: int, attack_range: int, gold_generation: int, cost: int, bon: String):
	nom.text = "Nom : " + buildingName
	hp.text = "Points de vie : " + str(pv)
	dmg.text = "Dégâts : " + str(degats)
	portee.text = "Portée : " +str(attack_range)
	goldGen.text = "Génération d'or : " + str(gold_generation)
	bonus.text = "Bonus : " + bon
	priceCost.text = "Coût : " + str(cost)
