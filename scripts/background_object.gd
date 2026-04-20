class_name BackgroundObject extends Node3D

@export var move_speed := 10.0

func _physics_process(delta: float) -> void:
	position.x -= move_speed * delta
