class_name Shark extends Node3D

@export var animation_player : AnimationPlayer
@export var bob_amplitude := 0.01
@export var bob_speed := 1.0

var starting_height : float
var is_mouth_open := false

func _ready() -> void:
	starting_height = position.y

func _physics_process(delta: float) -> void:
	var sine_value = sin(Time.get_ticks_msec() * bob_speed) * bob_amplitude
	position.y = starting_height + sine_value
	
func _on_open_mouth_area_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		if !is_mouth_open:
			is_mouth_open = true
			animation_player.play("open_mouth")

func _on_open_mouth_area_body_exited(body: Node3D) -> void:
	var player = body as Player
	if player:
		if is_mouth_open:
			is_mouth_open = false
			animation_player.play("close_mouth")

func _on_chomp_area_body_entered(body: Node3D) -> void:
	var fruit = body as Fruit
	if fruit:
		if is_mouth_open:
			is_mouth_open = false
			animation_player.play("quick_chomp")
		fruit.queue_free()
		give_axe()
		
func give_axe() -> void:
	# TODO : Give Axe
	pass
