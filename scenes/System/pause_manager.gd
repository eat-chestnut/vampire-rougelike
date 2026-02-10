extends Node

signal pause_changed(paused: bool)

func set_paused(paused: bool) -> void:
	if get_tree().paused == paused:
		return
	get_tree().paused = paused
	pause_changed.emit(paused)

func toggle_pause() -> void:
	set_paused(not get_tree().paused)
