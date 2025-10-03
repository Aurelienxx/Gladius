extends CheckButton


func _on_toggled(toggled_on):
	"""
	Change le mode d’affichage de la fenêtre.

	:param toggled_on: (bool) True si la case est cochée → plein écran,
							  False si décochée → fenêtré.
	:return: None
	"""
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
