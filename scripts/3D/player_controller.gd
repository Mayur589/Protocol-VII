extends Node3D

@export var walk_speed: float = 2.2
@export var mouse_sensitivity: float = 0.0014
@export var max_look_up_down_degrees: float = 75.0

@onready var body: CharacterBody3D = $CharacterBody3D
@onready var head: Node3D = $CharacterBody3D/head

var _pitch_radians: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	body.floor_stop_on_slope = true
	body.safe_margin = 0.03

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)

	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_mode()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_horizontal_movement()
	body.move_and_slide()

func _handle_mouse_look(relative: Vector2) -> void:
	body.rotate_y(-relative.x * mouse_sensitivity)

	var max_pitch := deg_to_rad(max_look_up_down_degrees)
	_pitch_radians = clamp(_pitch_radians - relative.y * mouse_sensitivity, -max_pitch, max_pitch)
	head.rotation.x = _pitch_radians

func _toggle_mouse_mode() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _apply_gravity(delta: float) -> void:
	if body.is_on_floor():
		if body.velocity.y < 0.0:
			body.velocity.y = -0.1
		return

	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	body.velocity.y -= gravity * delta

func _apply_horizontal_movement() -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var desired_direction := (body.global_basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	body.velocity.x = desired_direction.x * walk_speed
	body.velocity.z = desired_direction.z * walk_speed
