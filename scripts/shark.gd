class_name Shark extends Node3D

@export var animation_player : AnimationPlayer
@export var bob_amplitude := 0.01
@export var bob_speed := 1.0
@export var axe_scene : PackedScene
@export var axe_give_direction : Vector3
@export var axe_give_force := 1000.0
@export var axe_give_point : Node3D
@export var axe_give_delay_timer : Timer
@export var yum_audio : AudioStreamPlayer3D
@export var give_audio : AudioStreamPlayer3D
@export var open_audio : AudioStreamPlayer3D
@export var close_audio : AudioStreamPlayer3D

var starting_height : float
var is_mouth_open := false

func _ready() -> void:
	starting_height = position.y
	axe_give_delay_timer.timeout.connect(_give_axe_delay_timer_done)

func _physics_process(delta: float) -> void:
	var sine_value = sin(Time.get_ticks_msec() * bob_speed) * bob_amplitude
	position.y = starting_height + sine_value
	
func _on_open_mouth_area_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		if !is_mouth_open:
			is_mouth_open = true
			animation_player.play("open_mouth")
			open_audio.play()

func _on_open_mouth_area_body_exited(body: Node3D) -> void:
	var player = body as Player
	if player:
		if is_mouth_open:
			is_mouth_open = false
			animation_player.play("close_mouth")
			close_audio.play()

func _on_chomp_area_body_entered(body: Node3D) -> void:
	var fruit = body as Fruit
	if fruit:
		if is_mouth_open:
			is_mouth_open = false
			animation_player.play("quick_chomp")
			yum_audio.play()
		fruit.queue_free()
		axe_give_delay_timer.start()
		
func give_axe() -> void:
	var new_axe := axe_scene.instantiate() as Axe
	get_tree().root.add_child(new_axe)
	new_axe.global_position = axe_give_point.global_position
	var force_direction = (-global_transform.basis.z + axe_give_direction).normalized()
	var force = force_direction * axe_give_force
	new_axe.apply_force(force)
	give_audio.play()
	
func _give_axe_delay_timer_done() -> void:
	if !is_mouth_open:
		is_mouth_open = true
		animation_player.play("open_mouth")
		await get_tree().create_timer(0.5).timeout
		give_axe()
	
