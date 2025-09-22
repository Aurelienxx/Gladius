extends Control

var startValue: int = 0

func _ready() -> void:
	%LabelCurrentCapacity.text = str(startValue) + " / 100"

func updateCurrentMoney(value: int):
	startValue = value
	%LabelCurrentCapacity.text = str(startValue) + " / 100"
