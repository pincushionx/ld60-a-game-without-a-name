extends Node3D
class_name ShotHistory

const Trajectory = preload("res://Scripts/Projectile/shot_trajectory_3d.gd")

@export_range(0.0, 10.0, 0.01) var minimum_sample_distance : float = 0.25
@export var current_visible : bool = true:
	set(value):
		current_visible = value
		_update_visibility()
@export var previous_visible : bool = true:
	set(value):
		previous_visible = value
		_update_visibility()
@export var current_color : Color = Color(1.0, 0.85, 0.2):
	set(value):
		current_color = value
		_update_visuals()
@export var previous_color : Color = Color(0.3, 0.8, 1.0):
	set(value):
		previous_color = value
		_update_visuals()
@export var current_material : Material:
	set(value):
		current_material = value
		_update_visuals()
@export var previous_material : Material:
	set(value):
		previous_material = value
		_update_visuals()
@export var impact_color : Color = Color(1.0, 0.3, 0.1):
	set(value):
		impact_color = value
		_update_visuals()
@export_range(0.01, 5.0, 0.01) var impact_radius : float = 0.2:
	set(value):
		impact_radius = value
		_update_visuals()
@export var impact_material : Material:
	set(value):
		impact_material = value
		_update_visuals()
## Optional existing Input Map action; empty leaves visibility control to callers.
@export var toggle_previous_action : StringName = &""

var current_trajectory : ShotTrajectory3D
var previous_trajectory : ShotTrajectory3D
var impact_marker : MeshInstance3D
var _records : Dictionary = {}
var _current_id : int = 0
var _previous_points := PackedVector3Array()
var _has_impact : bool = false

func _enter_tree() -> void:
	add_to_group("shot_history")

func _ready() -> void:
	# World-space renderers stay fixed if the history's parent moves.
	top_level = true
	global_transform = Transform3D.IDENTITY
	current_trajectory = Trajectory.new()
	current_trajectory.name = "CurrentTrajectory"
	add_child(current_trajectory)
	previous_trajectory = Trajectory.new()
	previous_trajectory.name = "PreviousTrajectory"
	add_child(previous_trajectory)
	impact_marker = MeshInstance3D.new()
	impact_marker.name = "ImpactMarker"
	impact_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(impact_marker)
	_update_visuals()
	_update_visibility()

func _unhandled_input(event : InputEvent) -> void:
	if not toggle_previous_action.is_empty() and event.is_action_pressed(toggle_previous_action) and not event.is_echo():
		toggle_previous_visibility()
		get_viewport().set_input_as_handled()

func toggle_previous_visibility() -> void:
	previous_visible = not previous_visible

func set_current_visible(value : bool) -> void:
	current_visible = value

func set_previous_visible(value : bool) -> void:
	previous_visible = value

func get_previous_points() -> PackedVector3Array:
	return _previous_points.duplicate()

func track_projectile(projectile : Node3D) -> void:
	var id : int = projectile.get_instance_id()
	var started : Callable = _on_started.bind(id)
	if projectile.is_connected("flight_started", started):
		return
	projectile.connect("flight_started", started)
	projectile.connect("position_sampled", _on_sampled.bind(id))
	projectile.connect("flight_finished", _on_finished.bind(id))

func _on_started(position : Vector3, id : int) -> void:
	_records[id] = PackedVector3Array([position])
	_current_id = id
	current_trajectory.replace_trajectory(_records[id])

func _on_sampled(position : Vector3, id : int) -> void:
	if not _records.has(id):
		return
	var points : PackedVector3Array = _records[id]
	if points[-1].distance_squared_to(position) < minimum_sample_distance * minimum_sample_distance or points[-1] == position:
		return
	points.append(position)
	_records[id] = points
	if id == _current_id:
		current_trajectory.add_point(position)

func _on_finished(_gun : Gun, projectile : Projectile, enemy_hit : Enemy, id : int) -> void:
	if not _records.has(id):
		return
	var position : Vector3 = projectile.final_position
	var points : PackedVector3Array = _records[id]
	# Always retain the exact terminal point, even below the sampling threshold.
	if points[-1] != position:
		points.append(position)
	_previous_points = points
	previous_trajectory.replace_trajectory(points)
	_has_impact = enemy_hit != null
	impact_marker.global_position = position
	_records.erase(id)
	if id == _current_id:
		current_trajectory.clear_trajectory()
		_current_id = 0
		# Overlapping shots retain their own recordings; display the newest still flying.
		if not _records.is_empty():
			_current_id = _records.keys().back()
			current_trajectory.replace_trajectory(_records[_current_id])
	_update_visibility()

func _update_visibility() -> void:
	if is_instance_valid(current_trajectory):
		current_trajectory.visible = current_visible
	if is_instance_valid(previous_trajectory):
		previous_trajectory.visible = previous_visible
	if is_instance_valid(impact_marker):
		impact_marker.visible = previous_visible and _has_impact

func _update_visuals() -> void:
	if not is_instance_valid(current_trajectory):
		return
	current_trajectory.line_color = current_color
	current_trajectory.line_material = current_material
	previous_trajectory.line_color = previous_color
	previous_trajectory.line_material = previous_material
	var sphere := SphereMesh.new()
	sphere.radius = impact_radius
	sphere.height = impact_radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	impact_marker.mesh = sphere
	if impact_material != null:
		impact_marker.material_override = impact_material
	else:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = impact_color
		impact_marker.material_override = material
