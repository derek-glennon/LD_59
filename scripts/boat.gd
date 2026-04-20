class_name Boat extends Node3D

@export var bob_amplitude := 0.01
@export var bob_speed := 1.0

var starting_height : float

signal on_player_entered

func _ready() -> void:
	starting_height = position.y

func _physics_process(delta: float) -> void:
	var sine_value = sin(Time.get_ticks_msec() * bob_speed) * bob_amplitude
	position.y = starting_height + sine_value

func _on_end_game_area_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		on_player_entered.emit()
