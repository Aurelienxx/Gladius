extends Control

var startValue: int = 0

func _ready() -> void:
	%LabelProfit.text = str(startValue)

func _on_loss_updated(value: int):
	startValue -= value
	%LabelProfit.text = str(startValue) + " /turn"
	
func _on_gain_updated(value: int):
	startValue += value
	%LabelProfit.text = str(startValue) + " /turn"
