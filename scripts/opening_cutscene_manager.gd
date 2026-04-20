class_name OpeningCutsceneManager extends Node3D

@export var animation_player : AnimationPlayer
@export var start_label : Label
@export var quit_label : Label


func _ready() -> void:
	animation_player.animation_finished.connect(on_animation_finished)

func play_opening_animation() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_method(fade_text, 0.0, 1.0, 0.5)
	fade_tween.finished.connect(ready_to_play_animation)
	
func fade_text(value : float) -> void:
	start_label.label_settings.font_color.a = 1.0 - value
	start_label.label_settings.outline_color.a = 1.0 - value
	
func ready_to_play_animation() -> void:
	animation_player.play("opening")

func on_animation_finished(anim_name : String) -> void:
	var nodes = get_all_children(get_tree().root)
	for node in nodes:
		var bg = node as BackgroundObject
		if bg:
			bg.queue_free()
			
	get_tree().change_scene_to_file("res://scenes/island_scene.tscn")
	
func get_all_children(in_node,arr:=[]):
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr
