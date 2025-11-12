extends CanvasLayer

@export var level1Card : Control
@export var level2Card : Control
@export var level3Card : Control
var container: Control

func _ready():
	level1Card.hideBuyButton()

func displayCards(HQ1Data: Dictionary, HQ2Data: Dictionary, HQ3Data: Dictionary):
	level1Card.updateInfos(HQ1Data)
	level2Card.updateInfos(HQ2Data)
	level3Card.updateInfos(HQ3Data)
	
func _unhandled_input(event):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		visible = false

func hideBuyButton(level: int):
	if level == 2:
		level2Card.hideBuyButton()
	else:
		level3Card.hideBuyButton()
