extends Node3D

class_name ConsoleNumbers

@export_range(0.1, 100.0, 0.1) var first_wheel_speed : float = 20.0
@export_range(0.1, 1.0, 0.05) var speed_multiplier_per_wheel : float = 0.65

var wheel_container : Node3D
var wheels : Array[NumberWheel]

var target_number : int = 0
var _previous_target : int = 0
var _rotate_forward : bool = true

func _enter_tree() -> void:
	wheel_container = $Wheels
	wheels.clear()
	for child in wheel_container.get_children():
		if child is NumberWheel:
			wheels.append(child)
			child.target_number = 0
	_update_wheels()

func clear() -> void:
	target_number = 0
	_update_wheels()

func _process(_delta: float) -> void:
	if TimeKeeper.IsGameplayPaused:
		return

	_update_wheels()

func _update_wheels() -> void:
	var score : int = maxi(target_number, 0)
	if score != _previous_target:
		# Compare the whole number so carries/borrows turn every wheel consistently.
		_rotate_forward = score > _previous_target
		_previous_target = score
	var speed : float = first_wheel_speed
	# Child order starts with the units wheel. Update leading zeroes as well.
	for wheel : NumberWheel in wheels:
		wheel.rotate_forward = _rotate_forward
		wheel.speed_numbers_per_second = speed
		wheel.target_number = score % 10
		score = floori(score / 10.0)
		speed *= speed_multiplier_per_wheel
