extends Panel

@onready var nom: Label = $Name
@onready var hp: Label = $HBoxContainer/VBoxContainer/HP
@onready var dmg: Label = $HBoxContainer/VBoxContainer/DMG
@onready var portee: Label = $HBoxContainer/VBoxContainer/Range
@onready var goldGen: Label = $HBoxContainer/VBoxContainer2/GoldGeneration
@onready var bonus: Label = $HBoxContainer/VBoxContainer2/Bonus
@onready var buildingSprite: TextureRect = $BuildingSprite
@onready var priceCost: Label = $Cost

func showCard(buildingName: String, pv: int, degats: int, attack_range: int, gold_generation: int, cost: int, bon: String, SpritePath: String):
	nom.text = "Nom : " + buildingName
	hp.text = "Points de vie : " + str(pv)
	dmg.text = "Dégâts : " + str(degats)
	portee.text = "Portée : " +str(attack_range)
	goldGen.text = "Génération d'or : " + str(gold_generation)
	bonus.text = "Bonus : " + bon
	priceCost.text = "Coût : " + str(cost)
	buildingSprite.texture = load(SpritePath)

var HQ3 = {
	"name" : "QG3",
	"points_de_vie" : 150,
	"attack" : 15,
	"attack_range" : 7,
	"goldGen" : 25,
	"cost" : 150,
	"gain" : 30,
	"bonus" : "Gaz Moutarde",
	"Sprite" : "res://assets/sprites/EntitySprite/Units/SpriteTank/Tank1.png"
}

func _on_button_pressed() -> void:
	showCard(
		HQ3.get("name"), 
		HQ3.get("points_de_vie"), 
		HQ3.get("attack"), 
		HQ3.get("attack_range"), 
		HQ3.get("goldGen"), 
		HQ3.get("cost"),
		HQ3.get("bonus"),
		HQ3.get("Sprite"))
