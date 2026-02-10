extends Area2D

var _tween: Tween

func pickup(player: Player) -> void:
	if _tween != null and _tween.is_running():
		return
	_tween = create_tween()
	_tween.tween_method(_tween_pickup.bind(global_position, player), 0.0, 1.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	_tween.tween_callback(queue_free)

func _tween_pickup(percent: float, start_position: Vector2, player: Player) -> void:
	global_position = start_position.lerp(player.global_position, percent)
	
