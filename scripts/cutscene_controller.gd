class_name CutsceneController extends Node3D

@export_category("Components")
@export var animation_player : AnimationPlayer
@export var camera : Camera3D
@export var player : Player
@export var boat : Boat

@export_category("Leaving Animation")
@export var leaving_camera_point : Node3D
@export var leaving_camera_duration := 2.0
@export var leaving_camera_curve : Curve

var _before_animation_starting_position : Vector3
var _before_animation_starting_rotation : Vector3
var _camera_starting_position : Vector3
var _camera_starting_rotation : Vector3
var _ending_started := false

func _ready() -> void:
	animation_player.animation_finished.connect(on_animation_done)
	boat.on_player_entered.connect(on_player_entered_boat)

func _process(delta: float) -> void:
	if Input.is_action_just_released("DEBUG"):
		play_leaving_animation()
	if Input.is_action_just_released("DEBUG2"):
		return_from_leaving_animation()
		
func on_animation_done(anim_name : String) -> void:
	match anim_name:
		"leaving_setup":
			return_from_leaving_animation()
		"leaving":
			boat.visible = false
			await get_tree().create_timer(4.0).timeout
			get_tree().change_scene_to_file("res://scenes/ending_scene.tscn")

func play_leaving_animation() -> void:
	player.can_move = false
	_before_animation_starting_position = camera.global_position
	_before_animation_starting_rotation = camera.global_rotation
	_camera_starting_position = camera.global_position
	_camera_starting_rotation = camera.global_rotation
	var camera_move_tween = create_tween()
	camera_move_tween.tween_method(
		move_camera_to_location.bind(leaving_camera_point.global_position, leaving_camera_point.global_rotation),
		0.0,
		1.0,
		leaving_camera_duration)
	camera_move_tween.finished.connect(on_reached_leaving_animation_start_point)
		
func on_reached_leaving_animation_start_point() -> void:
	animation_player.play("leaving_setup")
		
func return_from_leaving_animation() -> void:
	_camera_starting_position = camera.global_position
	_camera_starting_rotation = camera.global_rotation
	var camera_move_tween = create_tween()
	camera_move_tween.tween_method(
		move_camera_to_location.bind(_before_animation_starting_position, _before_animation_starting_rotation),
		0.0,
		1.0,
		leaving_camera_duration)
	camera_move_tween.finished.connect(on_camera_returned_to_player)
		
func on_player_entered_boat() -> void:
	if !_ending_started:
		_ending_started = true
		player.reparent(boat, true)
		camera.reparent(self, true)
		player_ending_animation()
	
func player_ending_animation() -> void:
	player.can_move = false
	_before_animation_starting_position = camera.global_position
	_before_animation_starting_rotation = camera.global_rotation
	_camera_starting_position = camera.global_position
	_camera_starting_rotation = camera.global_rotation
	var camera_move_tween = create_tween()
	camera_move_tween.tween_method(
		move_camera_to_location.bind(leaving_camera_point.global_position, leaving_camera_point.global_rotation),
		0.0,
		1.0,
		leaving_camera_duration)
	camera_move_tween.finished.connect(ending_animation)
	
func ending_animation() -> void:
	animation_player.play("leaving")
	
func on_camera_returned_to_player() -> void:
	player.can_move = true

func move_camera_to_location(value : float, end_position : Vector3, end_rotation : Vector3) -> void:
	var t = leaving_camera_curve.sample(value)
	camera.global_position = lerp(_camera_starting_position, end_position, t)
	camera.global_rotation = lerp(_camera_starting_rotation, end_rotation, t)
