extends CharacterBody3D

class_name BasicFirstPersonPlayer

var _camera : Camera3D

var initial_camera_position : Vector3
var initial_camera_rotation : Vector3
var initial_camera_container : Node3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const CAMERA_SENSITIVITY = 0.25

var _look_rot : Vector2
const LOOK_RANGE_X = Vector2(-70, -25)

var _paused : bool = true
var _seated : bool = false

func _enter_tree() -> void:
	_camera = $Camera3D
	initial_camera_position = _camera.position
	initial_camera_rotation = _camera.rotation
	initial_camera_container = _camera.get_parent()

func _ready() -> void:
	_look_rot = Vector2(_camera.rotation_degrees.x, rotation_degrees.y)
	Unpause()

func reset_camera() -> void:
	_camera.position = initial_camera_position
	_camera.rotation = initial_camera_rotation
	_look_rot = Vector2(_camera.rotation_degrees.x, rotation_degrees.y)

func Unpause():
	_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func Pause():
	_paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func sit_down(marker : Marker3D) -> void:
	global_position = marker.global_position
	global_rotation = marker.global_rotation
	
	reparent(marker)
	
	velocity = Vector3.ZERO
	#_look_rot = Vector2(0.0, rotation_degrees.y)
	_look_rot = Vector2(-45, 0)
	_camera.rotation_degrees = Vector3(-45.0, 0.0, 0.0)
	_seated = true


func sit_up() -> void:
	reset_camera()
	reparent(Globals.player)
	_seated = false


func _physics_process(delta: float) -> void:
	if _paused:
		return

	if !_seated:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		if !velocity.is_zero_approx():
			move_and_slide()

	# Allow this rotation while seated
	_camera.rotation_degrees.x = _look_rot.x
	rotation_degrees.y = _look_rot.y

func _input(event):
	if _paused:
		return

	if event is InputEventMouseMotion:
		_look_rot.y -= (event.relative.x * CAMERA_SENSITIVITY)
		_look_rot.x -= (event.relative.y * CAMERA_SENSITIVITY)
		_look_rot.x = clamp(_look_rot.x, LOOK_RANGE_X.x, LOOK_RANGE_X.y)
