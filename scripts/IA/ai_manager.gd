extends Node

@export var AiTankManager: Node
@export var AiArtilleryManager: Node

func _ready() -> void:
	GlobalSignal.new_turn.connect(_play_AI_turn)


func _play_AI_turn() -> void:
	print("=== Nouveau tour de l'IA ===")

	for unit in GameState.all_units:
		if not unit.is_AI:
			continue
		if unit.equipe != GameState.current_player:
			continue

		var unit_name: String = unit.name_Unite

		match unit_name:
			"Camion", "Infanterie":
				print("Unité non gérée : ", unit_name)
			"Artillerie":
				print("Artillerie joue...")
				AiArtilleryManager._make_decision(unit)
			"Tank":
				print("Tank joue...")
				AiTankManager._ai_logic(unit)
			_:
				print("Unité inconnue : ", unit_name)

		# Petite pause pour le rythme visuel (facultatif)
		await get_tree().create_timer(1).timeout
