class_name Player extends CharacterBody3D

@export_category("Components")
@export var island_scene : Node3D
@export var camera : Camera3D
@export var player_mesh : MeshInstance3D
@export var body_animation_player : AnimationPlayer
@export var hand_animation_player : AnimationPlayer
@export var emote_animation_player : AnimationPlayer
@export var hand_attach_point : Node3D
@export var player_jump_audio : AudioStreamPlayer3D
@export var player_throw_audio : AudioStreamPlayer3D
@export var player_crash_audio : AudioStreamPlayer3D

@export_category("Movement")
@export var should_move_on_ready := true
@export var should_spawn_in_on_ready := false
@export var move_speed = 5.0
@export var jump_velocity = 4.5

@export_category("Grab/Throw")
@export var throw_strength = 1000.0

var can_move := true
var starting_position := Vector3.ZERO

var _interactables_in_range : Array[InteractableBase] = []
var _trees_in_range : Array[IslandTree] = []
var _grabbed_interactable : InteractableBase

func _ready() -> void:
	can_move = should_move_on_ready
	if should_spawn_in_on_ready:
		starting_position = position
		position.y += 10.0
		await get_tree().create_timer(0.5).timeout
		var spawn_tween = create_tween()
		spawn_tween.tween_property(self, "position", starting_position, 0.6).from_current()
		spawn_tween.finished.connect(on_spawn_done)
		
func on_spawn_done() -> void:
	player_crash_audio.play()
	await get_tree().create_timer(1.0).timeout
	can_move = true
	camera.reparent(self)
	
func _physics_process(delta: float) -> void:
	if can_move:
		# Player Rotation
		var mouse_position = get_viewport().get_mouse_position()
		var view_size = get_viewport().get_visible_rect().size
		var center_mouse_position = mouse_position - Vector2(view_size.x / 2, view_size.y /2)
		var angle = center_mouse_position.normalized().angle()
		player_mesh.rotation.y = -angle - PI/2
		
		# Grab/Throw
		if Input.is_action_just_released("Click"):
			var random_pitch = lerpf(0.9, 1.1, randf())
			player_throw_audio.pitch_scale = random_pitch
			player_throw_audio.play()
			hand_animation_player.play("Grab")
			# If we aren't holding anthing
			# See if there is anthing close to grab
			if !_grabbed_interactable:
				if _interactables_in_range.size() > 0:
					var closest_interactable = find_closest_interactable_in_range()
					grab_interactable(closest_interactable)
				elif _trees_in_range.size() > 0:
					var closest_tree = find_closest_tree_in_range()
					closest_tree.shake_tree()
			else:
				throw_interactable()
		
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = jump_velocity
			var random_pitch = lerpf(0.9, 1.2, randf())
			player_jump_audio.pitch_scale = random_pitch
			player_jump_audio.play()

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
		
		if velocity != Vector3.ZERO and is_on_floor():
			body_animation_player.play("Moving", 0.5)
		else:
			body_animation_player.play("RESET", 0.5)

		move_and_slide()

func find_closest_interactable_in_range() -> InteractableBase:
	var result : InteractableBase
	
	#early out
	if _interactables_in_range.size() == 0:
		return
		
	var closest_distance = 100000000.0
	for interactable in _interactables_in_range:
		var dist = interactable.global_position.distance_squared_to(global_position)
		if dist < closest_distance:
			closest_distance = dist
			result = interactable
	
	return result
	
func find_closest_tree_in_range() -> IslandTree:
	var result : IslandTree
	
	#early out
	if _trees_in_range.size() == 0:
		return
		
	var closest_distance = 100000000.0
	for tree in _trees_in_range:
		var dist = tree.global_position.distance_squared_to(global_position)
		if dist < closest_distance:
			closest_distance = dist
			result = tree
	
	return result
	

func grab_interactable(interactable : InteractableBase) -> void:
	_grabbed_interactable = interactable
	
	# Turn off the physics
	interactable.linear_velocity = Vector3.ZERO
	interactable.angular_velocity = Vector3.ZERO
	interactable.gravity_scale = 0.0
	interactable.set_collision_layer_value(1, false)
	
	# Swap parents - Kepe global transform
	interactable.reparent(hand_attach_point, true)
	
	# Set Position/Rotation
	interactable.position = interactable.attached_offset
	interactable.rotation = interactable.attached_rotation
	
	if _interactables_in_range.has(interactable):
		_interactables_in_range.erase(interactable)

func throw_interactable() -> void:
	if _grabbed_interactable:
		# Reparent - keep global transform
		_grabbed_interactable.reparent(island_scene, true)
	
		# Enable Physics
		_grabbed_interactable.gravity_scale = 1.0
		_grabbed_interactable.set_collision_layer_value(1, true)
		_grabbed_interactable.linear_velocity = velocity
		
		# Throw the interactable
		var force = -player_mesh.global_transform.basis.z * throw_strength
		_grabbed_interactable.apply_force(force)
	
		if !_interactables_in_range.has(_grabbed_interactable):
			_interactables_in_range.append(_grabbed_interactable)
	
		_grabbed_interactable = null

func _on_player_grab_area_body_entered(body: Node3D) -> void:
	var interactable = body as InteractableBase
	if interactable:
		if !_grabbed_interactable:
			if !_interactables_in_range.has(interactable):
				_interactables_in_range.append(interactable)
	var tree = body.owner as IslandTree
	if tree:
		if !_trees_in_range.has(tree):
			_trees_in_range.append(tree)

func _on_player_grab_area_body_exited(body: Node3D) -> void:
	var interactable = body as InteractableBase
	if interactable:
		if _interactables_in_range.has(interactable):
			_interactables_in_range.erase(interactable)
	var tree = body.owner as IslandTree
	if tree:
		if _trees_in_range.has(tree):
			_trees_in_range.erase(tree)
