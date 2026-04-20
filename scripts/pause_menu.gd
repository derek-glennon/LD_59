class_name PauseMenu extends CanvasLayer

@export var resume_label : Label
@export var restart_label : Label
@export var quit_label : Label

var _current_label : Label

func _process(delta: float) -> void:
	if Input.is_action_just_released("Click"):
		if _current_label:
			match _current_label:
				resume_label:
					visible = false
					get_tree().paused = false
				restart_label:
					get_tree().paused = false
					get_tree().change_scene_to_file("res://scenes/island_scene.tscn")
				quit_label:
					get_tree().quit()
		
func on_game_paused() -> void:
	await get_tree().process_frame
	visible = true

func _on_resume_mouse_entered() -> void:
	_current_label = resume_label

func _on_resume_mouse_exited() -> void:
	_current_label = null

func _on_restart_mouse_entered() -> void:
	_current_label = restart_label

func _on_restart_mouse_exited() -> void:
	_current_label = null

func _on_quit_mouse_entered() -> void:
	_current_label = quit_label
	
func _on_quit_mouse_exited() -> void:
	_current_label = null
