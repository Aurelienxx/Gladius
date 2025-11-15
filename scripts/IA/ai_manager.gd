extends Node

@export var AiTankManager: Node
@export var AiArtilleryManager: Node
@export var AiTruckManager: Node
@export var AiInfantryManager: Node

func _ready() -> void:
	GlobalSignal.new_turn.connect(_play_AI_turn)

func _play_turn(index_player:int) -> void:
	"""
		Joue un tour pour l'équipe du joueur donné en parametre 
		pour le joueur 1, on donne l'index 1
	"""
	print("=== Nouveau tour de l'IA ===")
	
	for unit in GameState.all_units:
		if not unit.is_AI:
			continue
		if unit.equipe != index_player:
			continue

		var unit_name: String = unit.name_Unite

		match unit_name:
			"Infanterie":
				print("Infanterie joue...")
				AiInfantryManager.IA_turn(unit)
			"Camion":
				print("Camion joue...")
				AiTruckManager.Ai_Truck(unit)
			"Artillerie":
				print("Artillerie joue...")
				#AiArtilleryManager._make_decision(unit)
				AiArtilleryManagerspecial.doYourStuff(unit)
			"Tank":
				print("Tank joue...")
				AiTankManager.play_unit(unit)
			_:
				print("Unité inconnue : ", unit_name)

		# Petite pause pour le rythme visuel (facultatif)
		await get_tree().create_timer(2).timeout
	
	# apres avoir fais joué toute les unités, on met fin au tour 
	await get_tree().create_timer(2).timeout
	GameState.try_ending_turn()

func _play_AI_turn() -> void:
	"""
		Verifie si le joueur a qui il est tour de joué est une IA, si oui, alors on fera joué toute les unités
	"""
	var current_player_turn = GameState.current_player
	if GameState.is_player_ai(current_player_turn):
		_play_turn(current_player_turn)
