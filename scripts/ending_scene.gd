extends Node3D

@export var player : Player

func _ready() -> void:
	player.emote_animation_player.play("dance")

func _process(delta: float) -> void:
	if Input.is_action_just_released("Click"):
		get_tree().quit()
