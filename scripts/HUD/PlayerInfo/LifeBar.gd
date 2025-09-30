extends Control

func _ready() -> void:
	%LabelLifeBar.text = "1000 / 1000"
	%ProgressLifeBar.value = 1000

func updateView(value: int):
	%LabelLifeBar.text = str(value) + " / 1000"
	%ProgressLifeBar.value = value
