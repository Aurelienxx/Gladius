extends Control

@export var volume_slider: HSlider 
#@export var mute_button: Button 
#@export var unmute_button: Button 
@export var fullscreen_toggle: CheckButton 
@export var back_button: Button 

func _ready() -> void:
	# Connecte les signaux
	volume_slider.value_changed.connect(_on_volume_changed)
	#mute_button.pressed.connect(_on_mute_pressed)
	#unmute_button.pressed.connect(_on_unmute_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_button_pressed)
	
	_load_settings()

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	ProjectSettings.set_setting("game/volume", value)

func _on_mute_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	ProjectSettings.set_setting("game/muted", true)

func _on_unmute_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	ProjectSettings.set_setting("game/muted", false)

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	ProjectSettings.set_setting("game/fullscreen", enabled)

func _load_settings() -> void:
	var volume = ProjectSettings.get_setting("game/volume", 30.0)
	var muted = ProjectSettings.get_setting("game/muted", false)
	var fullscreen = ProjectSettings.get_setting("game/fullscreen", false)

	volume_slider.value = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	fullscreen_toggle.button_pressed = fullscreen

func _on_back_button_pressed() -> void:
	visible = false
	GlobalSignal.showMainButtons.emit()
