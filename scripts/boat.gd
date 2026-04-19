class_name Boat extends Node3D

signal on_player_entered

func _on_end_game_area_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		on_player_entered.emit()
