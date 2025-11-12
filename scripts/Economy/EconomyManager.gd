extends Node

var EconomyTab = []

var ValueStorage = {
	"current_money":  200000, #200, 
	"money_gain":     0, 
	"money_loss" :    0, 
	"money_result":   0
}

var TEAM_COUNT
var current_player = 0 # no team 

func _ready() -> void:
	GlobalSignal.new_player_turn.connect(new_player)
	TEAM_COUNT = GameState.MAX_PLAYER
	for i in range(TEAM_COUNT):
		EconomyTab.append(ValueStorage.duplicate(true))

func new_player(newPlayer:int):
	current_player = newPlayer

func _get_team_tab():
	var index = current_player - 1
	return EconomyTab.get(index) # on covertie la team en index
	
func get_team_current_money() -> int:
	var money = EconomyTab[current_player]["current_money"]
	
	return money
	
func _update_profit(valueStorage) -> void:
	valueStorage["money_result"] = valueStorage["money_gain"] - valueStorage["money_loss"]
	GlobalSignal.current_Money_Gain_Or_Loss.emit(valueStorage["money_result"])
	
func economy_turn() -> void:
	"""
	Met à jour l’économie à chaque tour :
	- Ajoute le résultat économique (gains - pertes)
	- Empêche le solde de tomber sous 0
	- Émet des signaux globaux pour mettre à jour l’interface
	"""
	
	var TeamEconomy = _get_team_tab()
	TeamEconomy["current_money"] += TeamEconomy["money_result"]  
	TeamEconomy["current_money"] = max(TeamEconomy["current_money"], 0)
	
	GlobalSignal.current_Money_Amount.emit(TeamEconomy["current_money"])
	GlobalSignal.current_Money_Gain_Or_Loss.emit(TeamEconomy["money_result"])



func change_money_gain(addGain:int) -> void:
	"""
	Augmente le gain économique d’une équipe.
	Émet un signal global indiquant le nouveau total combiné (argent + gain).
	"""
	var TeamEconomy = _get_team_tab()
	TeamEconomy["money_gain"] += addGain
	_update_profit(TeamEconomy)

func change_money_loss(addLoss:int) -> void:
	"""
	Augmente la perte économique d’une équipe.
	Émet un signal global indiquant le total ajusté (argent - pertes).
	"""
	var TeamEconomy = _get_team_tab()
	TeamEconomy["money_loss"] += addLoss
	_update_profit(TeamEconomy)

func buy_something(price:int):
	"""
	Effectue un achat en retirant le prix de l’argent actuel.
	Émet un signal global pour mettre à jour l’affichage du montant.
	"""
	var TeamEconomy = _get_team_tab()
	TeamEconomy["current_money"] -= price
	# Signal le nouveau niveau d'argent
	GlobalSignal.current_Money_Amount.emit(TeamEconomy["current_money"]) 

func money_check(money_amount) -> bool:
	"""
	Renvoie si le joeuur a assez d'argent
	"""
	var TeamEconomy = _get_team_tab()
	if TeamEconomy["current_money"] >= money_amount:
		return true
	else : 
		return false

func reset_values() -> void:
	for team in EconomyTab:
		team["money_loss"] = 0
		team["money_gain"] = 0
		_update_profit(team)
