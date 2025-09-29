extends HSlider
@export var audioBusName: String

var audioBusId: int

func _ready():
	audioBusId = AudioServer.get_bus_index("Main menu music")
	
func _on_value_changed(sound_value: float) -> void:
	var db = linear_to_db(sound_value)
	AudioServer.set_bus_volume_db(audioBusId, db)
