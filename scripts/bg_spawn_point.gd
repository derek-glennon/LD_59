extends Node3D

@export var scenes_to_spawn : Array[PackedScene] = []
@export var spawn_delay := 5.0

var _current_scene_index := 0
var _current_delay_timer := 18.0

func _process(delta: float) -> void:
	_current_delay_timer += delta
	if _current_delay_timer >= spawn_delay:
		_current_delay_timer = 0.0
		spawn_bg_object()
		
func spawn_bg_object() -> void:
	if _current_scene_index >= scenes_to_spawn.size():
		_current_scene_index = 0
		
	var new_scene := scenes_to_spawn[_current_scene_index].instantiate() as BackgroundObject
	get_tree().root.add_child(new_scene)
	new_scene.global_position = global_position
	
	_current_scene_index += 1
		

func _on_end_bg_area_area_entered(area: Area3D) -> void:
	var background_object = area.owner as BackgroundObject
	if background_object:
		background_object.queue_free()
