class_name ItemDropper extends Node2D

@export var item_spawn_resources : Array[ItemSpawnResource]

func get_random_item_scene() -> PackedScene:
	if item_spawn_resources.is_empty():
		return null
	var total_weight: float = 0
	for item in item_spawn_resources:
		total_weight += item.weight
	
	var random_value = randf_range(0, total_weight)
	
	var tmp_weight: float = 0
	
	for item in item_spawn_resources:
		if random_value >= tmp_weight and random_value < tmp_weight + item.weight:
			return item.item_scene
		tmp_weight += item.weight
	return item_spawn_resources[0].item_scene
	
func drop_item() -> void:
	var item_scene: PackedScene = get_random_item_scene()
	if item_scene == null:
		return
	var item : Node2D = item_scene.instantiate()
	get_tree().current_scene.add_child(item)
	item.global_position = global_position
