class_name IslandTree extends Node3D

@export_category("Fruit Growing")
@export var should_spawn_fruit := false
@export var fruit_scene : PackedScene
@export var fruit_point : Node3D
@export var grow_time := 1.0
@export var regrow_delay := 5.0

@export_category("Shake")
@export var shake_duration := 1.0
@export var shake_amplitude := 0.02
@export var shake_wavelength := 10 * PI

@export_category("Audio")
@export var shake_audio : AudioStreamPlayer3D
@export var fruit_leave_audio : AudioStreamPlayer3D


var _spawned_fruit : InteractableBase
var _starting_shake_rotation := 0.0
var _current_regrow_timer := 0.0

func _ready() -> void:
	if should_spawn_fruit:
		spawn_fruit()
		
func _process(delta: float) -> void:
	if should_spawn_fruit and !_spawned_fruit and _current_regrow_timer != 0.0:
		_current_regrow_timer -= delta
		if _current_regrow_timer <= 0.0:
			_current_regrow_timer = 0.0
			spawn_fruit()
		
func spawn_fruit() -> void:
	var new_fruit := fruit_scene.instantiate() as InteractableBase
	fruit_point.add_child(new_fruit)
	new_fruit.global_position = fruit_point.global_position
	new_fruit.set_collision_layer_value(1, false)
	new_fruit.gravity_scale = 0.0
	new_fruit.scale = Vector3.ZERO
	var grow_tween = create_tween()
	grow_tween.tween_property(new_fruit, "scale", Vector3.ONE, grow_time)
	grow_tween.finished.connect(_on_fruit_grow_done.bind(new_fruit))
	
func _on_fruit_grow_done(new_fruit : InteractableBase) -> void:
	_spawned_fruit = new_fruit
	
func shake_tree() -> void:
	_starting_shake_rotation = rotation.z
	var shake_tween = create_tween()
	shake_tween.tween_method(_on_shake_tween, 0.0, 1.0, shake_duration)
	shake_tween.finished.connect(_on_shake_done)
	shake_audio.play()
	
func _on_shake_tween(value : float) -> void:
	var amplitude = lerpf(shake_amplitude, 0.0, value)
	var sine_value = amplitude * sin(value * shake_wavelength)
	rotation.z = _starting_shake_rotation + sine_value
	
func _on_shake_done() -> void:
	rotation.z = 0.0
	if _spawned_fruit:
		_spawned_fruit.reparent(get_tree().root, true)
		_spawned_fruit.set_collision_layer_value(1, true)
		_spawned_fruit.gravity_scale = 1.0
		_spawned_fruit = null
		_current_regrow_timer = regrow_delay
		fruit_leave_audio.play()
	
