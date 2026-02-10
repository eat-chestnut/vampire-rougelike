extends Node2D
class_name Health

signal damaged(current_health : float, max_health: float)
signal died()

@export var max_health: float = 100
var current_health: float
var is_dead: bool = false

const DEBUG: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	is_dead = false

func damage(damage_amount: float) -> void:
	if is_dead:
		return
	current_health = max(0, current_health - damage_amount)
	if DEBUG:
		print(current_health)
	emit_signal("damaged", current_health, max_health)
	
	if current_health <= 0:
		is_dead = true
		if DEBUG:
			print(4444)
		emit_signal("died")
