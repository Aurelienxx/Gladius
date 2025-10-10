extends Node2D

const EndScreen = preload("res://scenes/EndScreen/EndScreen.tscn")
const TurnPanel = preload("res://scenes/HUD/turn_panel.tscn")

@onready var tileMapManager:Node2D = $"../TileMapContainer"

@onready var all_units := GameState.all_units
@onready var all_buildings := GameState.all_buildings

var current_player = GameState.current_player

var turn_changing:bool = false

# General 

func _ready():
	GlobalSignal.hq_Destroyed.connect(gameOver)
	GlobalSignal.pass_turn.connect(next_turn)
	
	GlobalSignal.new_turn.connect(next_turn_display)
	GlobalSignal.new_turn.connect(gaz_attack)
	GlobalSignal.new_turn.connect(gaz_process)
	GlobalSignal.new_turn.connect(economy_manager)
	
	GlobalSignal.new_player_turn.connect(save_new_player)
	
func save_new_player(player:int):
	current_player = player 

func next_turn() -> void:
	if not turn_changing:
		tileMapManager.highlight_reset()
		GameState.next_player()
		GlobalSignal.new_turn.emit()
		
#### Economy 

func economy_manager() -> void:
	EconomyManager.reset_values()
	unit_economy()
	building_economy()
	EconomyManager.economy_turn()

func unit_economy():
	"""
	Met à jour les coûts d’entretien des unités pour chaque joueur.
	"""
	for unit in all_units:
		if unit.equipe == current_player:
			EconomyManager.change_money_loss(unit.maintenance)
	
func building_economy():
	"""
    Met à jour les gains des bâtiments capturés pour chaque joueur.
	"""
	for buiding in all_buildings:
		if buiding.equipe == current_player:
			EconomyManager.change_money_gain(buiding.current_gain)

##### Gaz

func gaz_attack() -> void: 
	for build in all_buildings:
		if build.get_script().resource_path.find("QG.gd") != -1 and build.equipe == current_player and build.lv==3:
			tileMapManager.attack_gaz(build)

func gaz_process() -> void:
	for unit in all_units:
		if unit.equipe == current_player:
			unit.movement = false
			unit.attack = false
			
			# Si une unité du joueur est dans une case gaz alors elle prends des dégats
			if  tileMapManager.is_in_gaz(unit) :
				unit.take_damage(25) # Appelle la fonction de mise à jour de la barre de vie de la cible
				if unit.current_hp <= 0:
					# Supprime l'entité du terrain et de la liste des unités
					all_units.erase(unit)
					unit.queue_free()

#### Display 

func next_turn_display() -> void:
	turn_changing = true
	var turn_panel = TurnPanel.instantiate()
	add_child(turn_panel)
	await turn_panel.show_turn_async()
	turn_changing = false

#### Game over 

func gameOver():
	"""
	Affiche l’écran de fin de partie pour l’équipe gagnante.
	"""
	var game_over = EndScreen.instantiate()
	add_child(game_over)
	game_over.change_result()
	get_tree().paused = true
