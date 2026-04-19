class_name LogCircle extends Node3D

@export var logs : Array[MeshInstance3D] = []
@export var fire : Node3D

var _number_of_logs := 0

func _on_log_snap_area_body_entered(body: Node3D) -> void:
	var log = body as Log
	if log:
		logs[_number_of_logs].visible = true
		_number_of_logs += 1
		if _number_of_logs == logs.size():
			start_fire()
		log.queue_free()
		
func start_fire() -> void:
	# TODO : Choreo
	fire.visible = true
		
