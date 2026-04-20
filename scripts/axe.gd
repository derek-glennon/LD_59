class_name Axe extends InteractableBase

@export var log_scene : PackedScene
@export var log_give_direction := Vector3.ZERO
@export var log_give_force := 100.0
@export var log_spawn_audio : AudioStreamPlayer3D	

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide(Vector3.ZERO, true)
	if collision_info:
		var tree = collision_info.get_collider().owner as IslandTree
		if tree:
			if linear_velocity.length_squared() > 10.0:
				tree.shake_tree()
				var new_log := log_scene.instantiate() as Log
				get_tree().root.add_child(new_log)
				new_log.global_position = collision_info.get_position()
				var force_direction = (collision_info.get_normal() + log_give_direction).normalized()
				var force = force_direction * log_give_force
				new_log.apply_force(force)
				log_spawn_audio.play()
