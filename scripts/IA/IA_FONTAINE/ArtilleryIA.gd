extends Node
class_name ArtilleryAI

var controled_units: Array = []
var equipe_ia: int = 2
@export var tileMapManager: Node
@export var main: Node


func _ready():
	GlobalSignal.new_player_turn.connect(_on_new_player_turn)


func _on_new_player_turn(player: int):
	if player != equipe_ia:
		return

	controled_units.clear()
	for unit in GameState.all_units:
		if unit.equipe == player and unit.name_Unite == "Artillerie":
			controled_units.append(unit)

	await do_your_thing()
	controled_units.clear()


func do_your_thing() -> void:
	for unit in controled_units:
		await _make_decision(unit)
		await get_tree().create_timer(0.3).timeout
	print("---------- Fin du tour ----------")


# =====================================================
# ===       SYSTÈME DE DÉCISION PAR SCORE         ====
# =====================================================

func _make_decision(unit) -> void:
	if unit.current_hp <= 0:
		return

	var scores = {
		"attack_only": _score_attack(unit),
		"move_then_attack": _score_move_then_attack(unit),
		"move_only": _score_move_only(unit),
	}

	var best_action = _choose_best_action(scores)

	match best_action:
		"attack_only":
			print(unit.name_Unite, "choisit d'attaquer directement.")
			await _attack_if_possible(unit)
		"move_then_attack":
			print(unit.name_Unite, "se déplace puis attaque.")
			await _move_towards_enemy(unit)
			await _attack_if_possible(unit)
		"move_only":
			print(unit.name_Unite, "se déplace.")
			await _move_towards_enemy(unit)


# =====================================================
# ===                 SCORES D'ACTIONS              ===
# =====================================================

func _score_attack(unit) -> float:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	for enemy in GameState.all_units:
		if enemy.equipe != unit.equipe:
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			if tileMapManager.is_adjacent_cells(start_cell, enemy_cell, unit.attack_range):
				return 10.0
	return -1.0


func _score_move_then_attack(unit) -> float:
	var start = tileMapManager.get_position_on_map(unit.global_position)
	var reachable_cells = tileMapManager.get_reachable_cells(tileMapManager.MAP, start, unit.move_range)
	if reachable_cells.is_empty():
		return 0.0

	var best_score = 0.0
	for cell in reachable_cells:
		for enemy in GameState.all_units:
			if enemy.equipe != unit.equipe:
				var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
				if tileMapManager.is_adjacent_cells(cell, enemy_cell, unit.attack_range):
					var dist = cell.distance_to(enemy_cell)
					var score = 10.0 - dist
					if score > best_score:
						best_score = score

	if best_score == 0.0:
		return -0.5
	return best_score


func _score_move_only(unit) -> float:
	var enemy = _get_closest_enemy(unit)
	if enemy == null:
		return 0.0
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
	var dist = start_cell.distance_to(enemy_cell)
	var val = 5.0 - dist
	if val > 0.0 :
		return val
	else:
		return 0.1



func _get_closest_enemy(unit):
	var closest = null
	var best_dist = INF
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	for enemy in GameState.all_units:
		if enemy.equipe != unit.equipe:
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			var dist = start_cell.distance_to(enemy_cell)
			if dist < best_dist:
				best_dist = dist
				closest = enemy
	return closest


func _choose_best_action(scores: Dictionary) -> String:
	var best_name := ""
	var best_score := -INF
	for name in scores.keys():
		var s = scores[name]
		if s > best_score:
			best_score = s
			best_name = name
	return best_name


# =====================================================
# ===      DÉPLACEMENT LOGIQUE VERS ENNEMI         ===
# =====================================================

func _move_towards_enemy(unit) -> void:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	var reachable_cells = tileMapManager.get_reachable_cells(tileMapManager.MAP, start_cell, unit.move_range)
	if reachable_cells.is_empty():
		print(unit.name_Unite, "ne peut pas se déplacer.")
		return

	var closest_enemy = _get_closest_enemy(unit)
	if closest_enemy == null:
		print(unit.name_Unite, "ne trouve aucun ennemi.")
		return

	var enemy_cell = tileMapManager.get_position_on_map(closest_enemy.global_position)

	# Cherche la cellule atteignable la plus proche de l’ennemi
	var best_cell = reachable_cells[0]
	var best_dist = best_cell.distance_to(enemy_cell)
	for cell in reachable_cells:
		var d = cell.distance_to(enemy_cell)
		if d < best_dist:
			best_dist = d
			best_cell = cell

	# Si déjà à portée, ne bouge pas
	if tileMapManager.is_adjacent_cells(start_cell, enemy_cell, unit.attack_range):
		print(unit.name_Unite, "est déjà à portée d’attaque, reste sur place.")
		return

	# Génère le chemin vers la meilleure cellule
	var path = tileMapManager.make_path(unit, best_cell, unit.move_range)
	if path.is_empty():
		print(unit.name_Unite, "n’a pas trouvé de chemin valide.")
		return

	print(unit.name_Unite, "avance logiquement vers :", best_cell)
	var manager: Node = unit.get_node("MovementManager")
	manager.set_path(path)
	await get_tree().create_timer(0.5).timeout


# =====================================================
# ===        ATTAQUE SI UNE CIBLE À PORTÉE          ===
# =====================================================

func _attack_if_possible(unit) -> void:
	var start_cell = tileMapManager.get_position_on_map(unit.global_position)
	for enemy in GameState.all_units:
		if enemy.equipe != unit.equipe:
			var enemy_cell = tileMapManager.get_position_on_map(enemy.global_position)
			if tileMapManager.is_adjacent_cells(start_cell, enemy_cell, unit.attack_range):
				print(unit.name_Unite, "attaque", enemy.name_Unite, "pour", unit.damage, "dégâts")
				main._on_unit_attack(unit, enemy)
				return
