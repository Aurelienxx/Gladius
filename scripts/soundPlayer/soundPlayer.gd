extends Node2D

@export var sound_player_node : AudioStreamPlayer2D

# nom du son -> chemin vers le son depuis res
const sound_library:Dictionary = {
	"explosion" : "res://assets/sound/explosion_snd.mp3",
	"gaz" : "res://assets/sound/gaz_snd.mp3",
} 


func _ready() -> void:
	GlobalSignal.playSound.connect(play_a_sound)


func play_a_sound(sound_name:String):
	if sound_name in sound_library:
		print("Playing sound ", sound_name, ".....")
		var soundSfx = load(sound_library[sound_name])
		sound_player_node.stream = soundSfx
		sound_player_node.play()
	else : 
		print("Invalid sound name : ", sound_name)
