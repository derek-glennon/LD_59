extends Node3D

@export var opening_cutscene_manager : OpeningCutsceneManager
@export var player : Player

enum CurrentMenuOption {
	NONE,
	START,
	QUIT
}
var current_menu_option := CurrentMenuOption.NONE

func _ready() -> void:
	player.emote_animation_player.play("dance")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Click"):
		match current_menu_option:
			CurrentMenuOption.START:
				opening_cutscene_manager.play_opening_animation()
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
