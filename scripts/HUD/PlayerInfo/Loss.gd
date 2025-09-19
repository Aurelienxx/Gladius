extends Control

var startValue: int = 0

signal loss_updated(new_value: int)

func _ready() -> void:
	%LabelLoss.text = str(startValue)

func updateLossValue(value: int):
	startValue += value
	%LabelLoss.text = "- " +str(startValue) + " /turn"
	emit_signal("loss_updated", value)
