extends Control
@onready var buttons: VBoxContainer = $Buttons
@onready var settings: Panel = $Settings

func _ready():
	settings.visible = false
	buttons.visible = true

func _on_back_button_pressed():
	settings.visible = false
	buttons.visible = true
	
func _on_start_button_pressed() -> void:
	#get_tree().change_scene_to_file()
	print("Starting game...")

func _on_exit_button_pressed():
	get_tree().quit()

func _on_parameters_button_pressed() -> void:
	buttons.visible = false
	settings.visible = true


func _on_back_settings_pressed() -> void:
	settings.visible = false
	buttons.visible = true
