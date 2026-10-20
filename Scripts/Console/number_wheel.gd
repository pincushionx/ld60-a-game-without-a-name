extends Node3D

class_name NumberWheel

## True advances 0 -> 1 -> ... -> 9 -> 0; false turns in reverse.
@export var rotate_forward : bool = true

var speed_numbers_per_second : float = 20
var target_number : float = 0
var degrees_per_number : float = 36.0

var model : Node3D
var _current_degrees : float = 0.0

func _enter_tree() -> void:
	model = $Model

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize()

func initialize() -> void:
	_current_degrees = fposmod(target_number * degrees_per_number, 360.0)
	model.rotation_degrees.x = _current_degrees

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if TimeKeeper.IsGameplayPaused:
		return

	var target_degrees : float = fposmod(target_number * degrees_per_number, 360.0)
	var direction : float = 1.0 if rotate_forward else -1.0
	var rotation_diff : float = fposmod((target_degrees - _current_degrees) * direction, 360.0)
	var move_this_frame : float = maxf(delta * speed_numbers_per_second * degrees_per_number, 0.0)
	if move_this_frame >= rotation_diff:
		_current_degrees = target_degrees
	else:
		_current_degrees = fposmod(_current_degrees + direction * move_this_frame, 360.0)
	model.rotation_degrees.x = _current_degrees
