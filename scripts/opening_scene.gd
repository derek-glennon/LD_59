extends Node3D

enum CurrentMenuOption {
	NONE,
	START,
	QUIT
}
var current_menu_option := CurrentMenuOption.NONE

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		match current_menu_option:
			CurrentMenuOption.START:
				get_tree().change_scene_to_file("res://scenes/island_scene.tscn")
			CurrentMenuOption.QUIT:
				get_tree().quit()

func _on_start_mouse_entered() -> void:
	current_menu_option = CurrentMenuOption.START

func _on_quit_mouse_entered() -> void:
	current_menu_option = CurrentMenuOption.QUIT
	
func _on_start_mouse_exited() -> void:
	current_menu_option = CurrentMenuOption.NONE
	
func _on_quit_mouse_exited() -> void:
	current_menu_option = CurrentMenuOption.NONE
