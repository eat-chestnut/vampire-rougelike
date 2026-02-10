extends ProgressBar

@export var health: Health
@export var is_player_health_bar: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if health == null:
		if is_player_health_bar:
			health = _resolve_player_health()
			if health == null:
				push_error("HealthBar: Player Health not found. Assign 'health' or add player to group 'player'.")
				return
		else:
			push_error("HealthBar: Health reference not assigned.")
			return
	call_deferred("initialize")

func initialize() -> void:
	max_value = health.max_health
	min_value = 0
	value = health.current_health
	
	if not health.damaged.is_connected(on_damaged):
		health.damaged.connect(on_damaged)
	
func on_damaged(current_health: float, max_health: float) -> void:
	max_value = max_health
	value = current_health

func _resolve_player_health() -> Health:
	var player: Node = null
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
	if player == null:
		var candidates := get_tree().current_scene.find_children("*", "Player", true, false)
		if not candidates.is_empty():
			player = candidates[0]
	if player == null:
		return null
	if player is Player:
		return (player as Player).health
	return player.get_node_or_null("Health") as Health
