extends Control

func updateView(value: int):
	%LabelLifeBar.text = str(value) + " / 1000"
	%ProgressLifeBar.value = value
