extends CharacterBody2D
class_name Player

@export var move_speed : int = 100
@export var animated_sprite_2d: AnimatedSprite2D
@export var knock_back: KnockBack
@onready var health: Health = _resolve_health()
@export var pickup_area: Area2D

var is_knocking_back : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if animated_sprite_2d == null or knock_back == null:
		push_error("Player: Missing exported node reference(s). Check AnimatedSprite2D/KnockBack assignment.")
		set_process(false)
		set_physics_process(false)
		return
	if pickup_area == null:
		push_error("Player: PickupArea not assigned. Item pickup will be disabled.")
	add_to_group("player")
	knock_back.start_knock_back.connect(on_start_knock_back)
	knock_back.stop_knock_back.connect(on_stop_knock_back)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_knocking_back:
		move_and_slide()
		return
	var move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_direction * move_speed
	handle_animation(move_direction)
	handle_rotation(move_direction)
	move_and_slide()

func handle_animation(move_direction: Vector2) -> void:
	if move_direction.length() > 0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")

func handle_rotation(move_direction: Vector2) -> void:
	if move_direction.x > 0:
		animated_sprite_2d.scale = Vector2(1, 1)
	elif move_direction.x < 0:
		animated_sprite_2d.scale = Vector2(-1, 1)

func on_start_knock_back(direction: Vector2, force: float, duration: float) -> void:
	is_knocking_back = true
	velocity = direction * force
	
	
func on_stop_knock_back() -> void:
	is_knocking_back = false
	velocity = Vector2.ZERO

func _on_health_died() -> void:
	get_tree().call_deferred("reload_current_scene")



func _on_pickup_area_area_entered(area: Area2D) -> void:
	area.pickup(self)

func _resolve_health() -> Health:
	var resolved := get_node_or_null("Health") as Health
	if resolved == null:
		push_error("Player: Health node not found. Expected child node 'Health'.")
		resolved = Health.new()
		resolved.name = "Health"
		add_child(resolved)
	return resolved
