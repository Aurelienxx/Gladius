extends HSlider
@export var audioBusName: String

var audioBusId: int

func _ready():
	"""
	Initialise l’ID du bus audio.
	"""
	audioBusId = AudioServer.get_bus_index("Main menu music")
	
func _on_value_changed(sound_value: float) -> void:
	"""
	Change le volume du bus audio lié au slider.

	:param sound_value: (float) Valeur linéaire du slider (0.0 à 1.0).
	:return: None
	"""
	var db = linear_to_db(sound_value)
	AudioServer.set_bus_volume_db(audioBusId, db)
