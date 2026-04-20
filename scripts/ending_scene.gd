extends Node3D

func _process(delta: float) -> void:
	if Input.is_action_just_released("Click"):
		get_tree().quit()
