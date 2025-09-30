extends Control

var startValue: int = 0

signal gain_updated(new_value: int)

func _ready() -> void:
	%LabelGain.text = str(startValue)

func updateGainValue(value: int):
	startValue = value
	%LabelGain.text = "+ " + str(startValue) + " /turn"
	emit_signal("gain_updated", startValue)
