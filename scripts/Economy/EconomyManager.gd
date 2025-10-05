extends Node

var current_money1 = 100
var money_gain1 = 0
var money_loss1 = 0
var money_result1 = 0

var current_money2 = 100
var money_gain2 = 0
var money_loss2 = 0
var money_result2 = 0

func economy_turn(current_money: int, economic_result: int) -> int:
	"""
	Met à jour l’économie à chaque tour :
	- Ajoute le résultat économique (gains - pertes)
	- Empêche le solde de tomber sous 0
	- Émet des signaux globaux pour mettre à jour l’interface
	"""
	current_money += economic_result
	current_money = max(current_money, 0)
	
	GlobalSignal.current_Money_Amount.emit(current_money)
	GlobalSignal.current_Money_Gain_Or_Loss.emit(economic_result)

	return current_money


func change_money_gain(current_money:int, money_gain: int, new_gain: int) -> int:
	"""
	Augmente le gain économique d’une équipe.
	Émet un signal global indiquant le nouveau total combiné (argent + gain).
	"""
	money_gain += new_gain
	
	GlobalSignal.current_Money_Gain_Or_Loss.emit(current_money + money_gain)

	return money_gain

func change_money_loss(current_money:int, money_loss: int, new_loss: int) -> int:
	"""
	Augmente la perte économique d’une équipe.
	Émet un signal global indiquant le total ajusté (argent - pertes).
	"""
	money_loss += new_loss
	
	GlobalSignal.current_Money_Gain_Or_Loss.emit(current_money - money_loss)
	
	return money_loss

func buy_something(current_money: int, price: int) -> int:
	"""
	Effectue un achat en retirant le prix de l’argent actuel.
	Émet un signal global pour mettre à jour l’affichage du montant.
	"""
	current_money -= price
	
	GlobalSignal.current_Money_Amount.emit(current_money)

	return current_money
