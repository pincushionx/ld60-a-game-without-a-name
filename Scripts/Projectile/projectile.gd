class_name Projectile
extends CharacterBody3D

signal flight_started(position : Vector3)
signal position_sampled(position : Vector3)
signal flight_finished(gun : Gun, projectile : Projectile, enemy_hit : Enemy)

@export var gravity_scale: float = 1.0
@export var damage: float = 10.0
@export var max_lifetime: float = 20.0

var lifetime: float = 0.0
var gun : Gun
var final_position : Vector3
var _recording_started : bool = false
var _finished : bool = false

func _ready() -> void:
	var history : Node = get_tree().get_first_node_in_group("shot_history")
	if history != null:
		history.track_projectile(self)

func _start_recording() -> void:
	if not _recording_started:
		_recording_started = true
		flight_started.emit(global_position)

func _finish_recording(position : Vector3, enemy_hit : Enemy = null) -> void:
	if _finished:
		return
	_start_recording()
	_finished = true
	final_position = position
	flight_finished.emit(gun if is_instance_valid(gun) else null, self, enemy_hit)

func _exit_tree() -> void:
	# External deletion still preserves the last observed position as a missed shot.
	_finish_recording(global_position)


func launch(start_position: Vector3, initial_velocity: Vector3, firing_gun : Gun = null) -> void:
	gun = firing_gun
	global_position = start_position
	velocity = initial_velocity
	_start_recording()


func _physics_process(delta: float) -> void:
	_start_recording()
	lifetime += delta

	if lifetime >= max_lifetime:
		_finish_recording(global_position)
		queue_free()
		return

	velocity += get_gravity() * gravity_scale * delta

	var collision := move_and_collide(velocity * delta)
	position_sampled.emit(global_position)

	if collision:
		impact(collision)


func impact(collision: KinematicCollision3D) -> void:
	var collider := collision.get_collider()
	var hit_position := collision.get_position()

	print("Hit ", collider, " at ", hit_position)

	if collider is Enemy:
		_finish_recording(hit_position, collider)
		collider.hit(self)
	else:
		_finish_recording(hit_position)

	# Eventually:
	# - damage enemy
	# - create explosion
	# - camera shake
	# - crater/decal
	# - sound

	queue_free()
