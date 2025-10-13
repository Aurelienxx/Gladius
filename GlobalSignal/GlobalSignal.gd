extends Node

signal Unit_Clicked(unit)
signal Unit_Attack_Clicked(unit, target)
signal HeadQuarter_Clicked(headquarter)

signal current_Money_Amount(amount:int)
signal current_Money_Gain_Or_Loss(amount:int)

signal spawn_Unit(unit)
signal unitDied(_unit)
signal unitBought(unit)
signal hq_Destroyed()
signal new_player_turn(team:int)

signal new_turn()
signal pass_turn()

signal attack_occured_pos(attack_position:Vector2i)
signal unit_spawn_pos(spawn_position:Vector2i)
