extends Control

signal buyingUpgrade(level: int)

@export var BuildingName : Label
@export var MaxHPValue : Label
@export var DamageValue : Label
@export var AttackRangeValue : Label
@export var GainValue : Label
@export var Bonus : Label
@export var Sprite : TextureRect
@export var CostValue : Label
@export var BuyButton : Button

var level: int
func updateInfos(BuildingData: Dictionary):
	BuildingName.text = "Nom : " + BuildingData["name"]
	MaxHPValue.text = str(BuildingData["max_hp"])
	DamageValue.text = str(BuildingData["damage"])
	AttackRangeValue.text = str(BuildingData["attack_range"])
	GainValue.text = str(BuildingData["gain"])
	Bonus.text = "Bonus : " + BuildingData["bonus"]
	Sprite.texture = load(BuildingData["Sprite"])
	CostValue.text = "Coût : " + str(BuildingData["prix"])
	level = BuildingData["lvl"]

func hideBuyButton():
	BuyButton.visible = false

func _on_buy_button_pressed() -> void:
	GlobalSignal.buyingUpgrade.emit((level))
