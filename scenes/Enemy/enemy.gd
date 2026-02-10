extends CharacterBody2D
class_name Enemy

@export var chase_area: Area2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var attack_area: Area2D
@onready var health: Health = _resolve_health()
@export var item_dropper: ItemDropper

@export var move_speed: int = 50
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if chase_area == null or animated_sprite_2d == null or attack_area == null or item_dropper == null:
		push_error("Enemy: Missing exported node reference(s). Check ChaseArea/AnimatedSprite2D/AttackArea/ItemDropper assignment.")
		set_process(false)
		set_physics_process(false)
		return
	chase_area.body_entered.connect(on_body_enter_chase_area)
	chase_area.body_exited.connect(on_body_exit_chase_area)
	attack_area.body_entered.connect(on_body_enter_attack_area)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	chase_player()
	
func on_body_enter_chase_area(body: Node2D) -> void:
	if body is Player:
		player = body
		
func on_body_exit_chase_area(body: Node2D) -> void:
	if body is Player:
		player = null

func on_body_enter_attack_area(body: Node2D) -> void:
	if body is Player:
		var player_body := body as Player
		if player_body.health == null:
			push_error("Enemy: Player Health not found. Expected Player.health to be set.")
		else:
			var damage_amount = 40
			player_body.health.damage(damage_amount)
		if player_body.knock_back == null:
			push_error("Enemy: Player KnockBack not found. Expected Player.knock_back to be set.")
		else:
			var direction: Vector2 = (body.global_position - global_position).normalized()
			var force: float = 250
			var duration: float = 0.1
			player_body.knock_back.apply_knock_back(direction, force, duration)

func chase_player() -> void:
	var chase_direction: Vector2 = Vector2.ZERO
	
	if player != null:
		chase_direction = (player.global_position - global_position).normalized()
		
	velocity = chase_direction * move_speed
	handle_animation(chase_direction)
	handle_rotation(chase_direction)
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

func _on_health_died() -> void:
	item_dropper.drop_item()
	queue_free()

func _resolve_health() -> Health:
	var resolved := get_node_or_null("Health") as Health
	if resolved == null:
		push_error("Enemy: Health node not found. Expected child node 'Health'.")
		resolved = Health.new()
		resolved.name = "Health"
		add_child(resolved)
	return resolved
