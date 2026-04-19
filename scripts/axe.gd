class_name Axe extends InteractableBase

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide(Vector3.ZERO, true)
	if collision_info:
		var tree = collision_info.get_collider().owner as IslandTree
		if tree:
			if linear_velocity.length_squared() > 10.0:
				tree.shake_tree()
				# TODO : Spawn Log
