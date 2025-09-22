extends Control

var startValue: int = 20

func _ready() -> void:
	%LabelCurrentMoney.text = str(startValue)

func updateCurrentMoney(value: int):
	startValue = value
	%LabelCurrentMoney.text = str(startValue)
