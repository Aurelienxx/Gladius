extends Node

var current_money = 100
var money_gain = 0
var money_loose = 0
var economic_result = 0

func _ready():
	money_gain = change_money_gain(money_gain, 25)
	money_loose = change_money_loose(money_loose, 15)
	
	print("Vous possédez actuellement ", current_money , " argent")
	print("Au début du tour, vous remporterez ", money_gain , " et perdrez ", money_loose)
	
	economic_result = change_money_result(money_gain,money_loose)
	print("Vous aurez donc un résultat de ",economic_result," argent")
	print()

	current_money = economy_turn(current_money, economic_result)
	print("Le tour a commencé, vous possédez maintenant ", current_money, " argent")
	
	print()
	current_money = buy_something(current_money,50)
	print("Nouvelle unité achetée! Vous possédez maintenant ", current_money, " argent")
	
	
func economy_turn(current_money,economic_result) :
	current_money += economic_result
	if current_money < 0 :
		current_money = 0
	return current_money
	
func change_money_result(money_gain,money_loose) :
	var economic_result
	economic_result = money_gain - money_loose
	return economic_result
	
func change_money_gain(money_gain,new_gain) :
	money_gain += new_gain
	return money_gain
	
func change_money_loose(money_loose,new_loose) :
	money_loose += new_loose
	return money_loose
	
func buy_something(current_money,price) :
	current_money-= price
	return current_money
