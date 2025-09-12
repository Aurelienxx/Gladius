extends Node2D

func _ready():
	$MainTheme.play()

func _on_setting_button_pressed():
	$MenuPrincipal.visible = false
	$MenuSetting.visible = true

func _on_back_button_pressed():
	$MenuSetting.visible = false
	$MenuPrincipal.visible = true
	
func _on_start_button_pressed() -> void:
	print("Starting game...")

func _on_exit_button_pressed():
	get_tree().quit()

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
