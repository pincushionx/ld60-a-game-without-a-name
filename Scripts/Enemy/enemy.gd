extends AnimatableBody3D

class_name Enemy

signal navigation_finished(enemy : Enemy)

@export_range(0.0, 100.0, 0.1) var movement_speed : float = 2.0
@export_range(0.1, 30.0, 0.1) var rotation_response : float = 8.0

@export_group("Terrain Placement")
@export_flags_3d_physics var terrain_collision_mask : int = 1
@export_range(1.0, 2000.0, 1.0) var ground_probe_height : float = 500.0
@export_range(1.0, 2000.0, 1.0) var ground_probe_depth : float = 1000.0
## Enemy origin is at its feet. Increase only for models with a different pivot.
@export var ground_offset : float = 0.0

@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D

var last_move_end_time : float = -1.0

var _moving : bool = false
var _target : Vector3
var _desired_velocity : Vector3 = Vector3.ZERO
var _awaiting_velocity : bool = false
var _target_needs_projection : bool = false
var _ground_normal : Vector3 = Vector3.UP
var _target_rotation : Quaternion = Quaternion.IDENTITY
var _progress_position : Vector3
var _stalled_seconds : float = 0.0
var _move_seconds_left : float = 0.0

func _finish_movement() -> void:
	if not _moving:
		return
	_moving = false
	_awaiting_velocity = false
	_desired_velocity = Vector3.ZERO
	navigation_agent.velocity = Vector3.ZERO
	navigation_agent.set_velocity_forced(Vector3.ZERO)
	last_move_end_time = TimeKeeper.PlayTimeElapsed
	navigation_finished.emit(self)

# Keep XZ coordinates intact; terrain collision supplies the height.
# If collision is not ready or the ray misses, preserve the supplied position.
func _ground_position(position : Vector3, update_normal : bool = false) -> Vector3:
	if not is_inside_tree():
		return position
	var query := PhysicsRayQueryParameters3D.create(
		position + Vector3.UP * ground_probe_height,
		position - Vector3.UP * ground_probe_depth,
		terrain_collision_mask)
	var excluded : Array[RID] = [get_rid()]
	var space : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	while true:
		query.exclude = excluded
		var hit : Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return position
		var collider : Object = hit["collider"]
		# Other units and projectiles must never become stepping stones.
		if collider is Enemy or collider is CharacterBody3D:
			excluded.append(hit["rid"])
			continue
		position.y = (hit["position"] as Vector3).y + ground_offset
		if update_normal:
			_ground_normal = (hit["normal"] as Vector3).normalized()
		return position
	return position

func _place_on_ground(position : Vector3) -> void:
	global_position = _ground_position(position, true)
	var facing_target : Vector3 = global_position - global_basis.z
	if is_instance_valid(Globals.player):
		var player : Node3D = Globals.player.player_character
		if not is_instance_valid(player):
			player = Globals.player
		facing_target = player.global_position
	_align_to_terrain(facing_target)

func _align_to_terrain(facing_target : Vector3) -> void:
	var forward : Vector3 = facing_target - global_position
	forward.y = 0.0
	if forward.length_squared() < 0.000001:
		forward = -global_basis.z
		forward.y = 0.0
	if forward.length_squared() < 0.000001 or absf(_ground_normal.y) < 0.0001:
		return
	# Lift the heading onto the slope without changing its horizontal bearing.
	forward.y = -_ground_normal.dot(forward) / _ground_normal.y
	forward = forward.normalized()
	var right : Vector3 = forward.cross(_ground_normal).normalized()
	# Models face local -Z, and their local Y follows the terrain normal.
	_target_rotation = Basis(right, _ground_normal, -forward).get_rotation_quaternion()

func _interpolate_rotation(delta : float) -> void:
	var current : Quaternion = global_basis.orthonormalized().get_rotation_quaternion()
	var weight : float = 1.0 - exp(-rotation_response * delta)
	global_basis = Basis(current.slerp(_target_rotation, weight)).scaled_local(global_basis.get_scale())

func _ready() -> void:
	# Movement is already driven by physics ticks, so no deferred transform sync is needed.
	sync_to_physics = false
	_target_rotation = global_basis.orthonormalized().get_rotation_quaternion()
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	if _moving:
		navigation_agent.target_position = _target
	
	last_move_end_time = TimeKeeper.PlayTimeElapsed

func hit(_projectile : Projectile) -> void:
	Logs.Debug("Enemy %s destroyed" % name)
	queue_free()

# Destinations are world-space positions. The agent supplies the path, not movement.
func move_to(destination : Vector3) -> void:
	_progress_position = global_position
	_stalled_seconds = 0.0
	_move_seconds_left = maxf(10.0, global_position.distance_to(destination) / maxf(movement_speed, 0.1) * 3.0 + 5.0)
	_target = destination
	_target_needs_projection = true
	_moving = true
	_awaiting_velocity = false
	if is_node_ready():
		navigation_agent.target_position = destination

func move_to_immediately(destination : Vector3) -> void:
	_moving = false
	_awaiting_velocity = false
	_desired_velocity = Vector3.ZERO
	# Bypass AnimatableBody3D's deferred transform synchronization for teleporting.
	sync_to_physics = false
	_place_on_ground(destination)
	global_basis = Basis(_target_rotation).scaled_local(global_basis.get_scale())
	_target = global_position
	_target_needs_projection = false
	reset_physics_interpolation()
	if is_node_ready():
		navigation_agent.target_position = _target
		navigation_agent.velocity = Vector3.ZERO
		navigation_agent.set_velocity_forced(Vector3.ZERO)

func _physics_process(delta : float) -> void:
	# Also correct initial placement once terrain physics becomes available.
	_place_on_ground(global_position)
	# Interpolate once per physics tick, including while stationary.
	_interpolate_rotation(delta)
	if not _moving:
		return
	# Missing navigation data or blocked avoidance must not hold the turn forever.
	_move_seconds_left -= delta
	_stalled_seconds += delta
	if global_position.distance_squared_to(_progress_position) >= 0.0025:
		_progress_position = global_position
		_stalled_seconds = 0.0
	if _stalled_seconds >= 3.0 or _move_seconds_left <= 0.0:
		_finish_movement()
		return
	var navigation_map : RID = navigation_agent.get_navigation_map()
	if not navigation_map.is_valid() or NavigationServer3D.map_get_iteration_id(navigation_map) == 0:
		return
	if _target_needs_projection:
		_target = _ground_position(_target)
		navigation_agent.target_position = _target
		_target_needs_projection = false
	var next_position : Vector3 = navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished():
		_finish_movement()
		return
	# Clamp the step to avoid overshooting the next waypoint.
	_desired_velocity = (_ground_position(next_position) - global_position).limit_length(movement_speed * delta) / delta
	if navigation_agent.avoidance_enabled:
		_awaiting_velocity = true
		navigation_agent.velocity = _desired_velocity
	else:
		_place_on_ground(global_position + _desired_velocity * delta)

func _on_velocity_computed(safe_velocity : Vector3) -> void:
	if not _moving or not _awaiting_velocity:
		return
	_awaiting_velocity = false
	# Ground avoidance solves XZ only; preserve the path's vertical movement.
	if not navigation_agent.use_3d_avoidance:
		safe_velocity.y = _desired_velocity.y
	_place_on_ground(global_position + safe_velocity * get_physics_process_delta_time())
