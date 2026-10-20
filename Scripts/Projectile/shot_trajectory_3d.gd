extends Node3D
class_name ShotTrajectory3D

const RIBBON_WIDTH : float = 0.25

@export var line_color : Color = Color(1.0, 0.8, 0.2, 1.0):
	set(value):
		line_color = value
		_update_material()
@export var line_material : Material:
	set(value):
		line_material = value
		_update_material()

var _points := PackedVector3Array()
var _mesh := ImmediateMesh.new()
var _mesh_instance : MeshInstance3D
var _dirty : bool = false

func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh_instance)
	set_notify_transform(true)
	_update_material()
	_queue_rebuild()

func _notification(what : int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_queue_rebuild()

func add_point(world_position : Vector3) -> void:
	_points.append(world_position)
	_queue_rebuild()

func replace_trajectory(world_positions : PackedVector3Array) -> void:
	_points = world_positions.duplicate()
	_queue_rebuild()

func clear_trajectory() -> void:
	_points.clear()
	_queue_rebuild()

func get_points() -> PackedVector3Array:
	return _points.duplicate()

func _queue_rebuild() -> void:
	if _dirty or not is_inside_tree():
		return
	_dirty = true
	_rebuild.call_deferred()

func _rebuild() -> void:
	_dirty = false
	if not is_inside_tree():
		return
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var inverse : Transform3D = global_transform.affine_inverse()
	# Offset before converting to local space so width stays 0.25m on world X.
	var half_width : Vector3 = Vector3.RIGHT * RIBBON_WIDTH * 0.5
	for i : int in range(_points.size() - 1):
		var a : Vector3 = inverse * (_points[i] - half_width)
		var b : Vector3 = inverse * (_points[i] + half_width)
		var c : Vector3 = inverse * (_points[i + 1] - half_width)
		var d : Vector3 = inverse * (_points[i + 1] + half_width)
		_mesh.surface_add_vertex(a)
		_mesh.surface_add_vertex(b)
		_mesh.surface_add_vertex(c)
		_mesh.surface_add_vertex(b)
		_mesh.surface_add_vertex(d)
		_mesh.surface_add_vertex(c)
	_mesh.surface_end()

func _update_material() -> void:
	if not is_instance_valid(_mesh_instance):
		return
	if line_material != null:
		_mesh_instance.material_override = line_material
	else:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = line_color
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh_instance.material_override = material
