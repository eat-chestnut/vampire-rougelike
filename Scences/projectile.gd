extends Node2D
class_name Projectile

@onready var area_2d: Area2D = $Area2D
@export var flying_speed : int = 300
@export var impact_effect_scene: PackedScene

var flying_direction : Vector2

func set_up(flying_direction: Vector2) -> void:
	self.flying_direction = flying_direction.normalized()
	rotate(flying_direction.angle())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_2d.body_entered.connect(on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position += flying_direction * flying_speed * delta
	pass

func on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		var enemy_health: Health = body.get_node_or_null("Health")
		if enemy_health != null:
			var damage_amount = 40
			enemy_health.damage(damage_amount)
	var impact_effect: Node2D = impact_effect_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(impact_effect)
	impact_effect.global_position = global_position
	queue_free()
