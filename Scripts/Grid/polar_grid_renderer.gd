@tool
extends Node3D
class_name PolarGridRenderer

const Grid = preload("res://Scripts/Grid/grid_manager.gd")
enum RaycastFallback { PLANAR, SKIP_SEGMENT }

@export_range(1, 100, 1) var ring_count : int = 8:
	set(value):
		ring_count = value
		_queue_rebuild()

@export_range(1, 100, 1) var sector_count : int = 16:
	set(value):
		sector_count = value
		_queue_rebuild()

@export var inner_radius : float = 5.0:
	set(value):
		inner_radius = value
		_queue_rebuild()

@export var ring_width : float = 3.0:
	set(value):
		ring_width = value
		_queue_rebuild()

@export_range(1.0, 360.0, 1.0) var arc_degrees : float = 180.0:
	set(value):
		arc_degrees = value
		_queue_rebuild()

@export var line_color : Color = Color(0.45, 0.75, 0.5, 0.8):
	set(value):
		line_color = value
		_queue_rebuild()

@export var line_material : Material = null:
	set(value):
		line_material = value
		_queue_rebuild()

@export_range(0.01, 2.0, 0.01) var line_thickness : float = 0.08:
	set(value):
		line_thickness = value
		_queue_rebuild()

@export_range(1, 32, 1) var subdivisions_per_sector : int = 4:
	set(value):
		subdivisions_per_sector = value
		_queue_rebuild()

@export var surface_offset : float = 0.05:
	set(value):
		surface_offset = value
		_queue_rebuild()

@export_flags_3d_physics var terrain_collision_mask : int = 1:
	set(value):
		terrain_collision_mask = value
		_queue_rebuild()

@export var raycast_height : float = 100.0:
	set(value):
		raycast_height = value
		_queue_rebuild()

@export var raycast_depth : float = 200.0:
	set(value):
		raycast_depth = value
		_queue_rebuild()

@export var project_to_surface : bool = true:
	set(value):
		project_to_surface = value
		_queue_rebuild()

@export var raycast_fallback : RaycastFallback = RaycastFallback.PLANAR:
	set(value):
		raycast_fallback = value
		_queue_rebuild()

@export_tool_button("Rebuild Grid")
var rebuild_action : Callable = rebuild_grid

var _pending : bool = false
var _runtime_physics_ready : bool = false
var _mesh_instance : MeshInstance3D
var _space : PhysicsDirectSpaceState3D
var _samples : Dictionary = {}
var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _up : Vector3
var _inverse : Transform3D
var _misses : int = 0

func _ready() -> void:
	set_notify_transform(true)
	rebuild_grid()

func _notification(what : int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_queue_rebuild()

func _queue_rebuild() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	if Engine.is_editor_hint():
		_build_grid.call_deferred()
	else:
		# Runtime queries execute only during a physics tick.
		set_physics_process(true)

func rebuild_grid() -> void:
	_queue_rebuild()

func _physics_process(_delta : float) -> void:
	if not _runtime_physics_ready:
		# The first tick can precede deferred CSG collision creation and physics sync.
		_runtime_physics_ready = true
		return
	set_physics_process(false)
	if _pending:
		_build_grid()

func _build_grid() -> void:
	_pending = false
	if not is_inside_tree():
		return
	if not is_instance_valid(_mesh_instance):
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "_PolarGridMesh"
		_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_BACK)
		# No owner: generated geometry is never serialized with the scene.
	_mesh_instance.mesh = null
	if ring_count < 1 or sector_count < 1 or inner_radius < 0.0 or ring_width <= 0.0 or arc_degrees <= 0.0 or arc_degrees > 360.0 or subdivisions_per_sector < 1 or line_thickness <= 0.0 or absf(global_transform.basis.determinant()) < 0.000001:
		push_warning("Polar grid requires positive dimensions and an invertible transform.")
		return
	_up = global_transform.basis.y.normalized()
	_inverse = global_transform.affine_inverse()
	_space = null
	if project_to_surface and get_world_3d() != null:
		_space = get_world_3d().direct_space_state
	_samples.clear()
	_vertices.clear()
	_normals.clear()
	_misses = 0
	var grid : GridManager = get_parent() as GridManager
	var standalone : bool = grid == null
	if standalone:
		grid = Grid.new()
		grid.ring_count = ring_count
		grid.sector_count = sector_count
		grid.inner_radius = inner_radius
		grid.ring_width = ring_width
		grid.arc_degrees = arc_degrees
	var closed : bool = arc_degrees == 360.0
	var arc_steps : int = sector_count * subdivisions_per_sector
	for ring : int in range(ring_count + 1):
		if grid.get_ring_inner_radius(ring) <= 0.0:
			continue
		var points := PackedVector3Array()
		for step : int in range(arc_steps + 1):
			var sector_position : float = float(step) / subdivisions_per_sector
			points.append(grid.cell_to_local(Vector2i(ring, floori(sector_position)), Vector2(sector_position - floorf(sector_position), 0)))
		if closed:
			points[points.size() - 1] = points[0]
		_append_ribbon(points, closed)
	# A full circle shares its first and last spoke.
	for sector : int in range(sector_count if closed else sector_count + 1):
		var points := PackedVector3Array()
		for step : int in range(ring_count * subdivisions_per_sector + 1):
			var ring_position : float = float(step) / subdivisions_per_sector
			points.append(grid.cell_to_local(Vector2i(floori(ring_position), sector), Vector2(0, ring_position - floorf(ring_position))))
		_append_ribbon(points, false)
	if standalone:
		grid.free()
	if not _vertices.is_empty():
		var arrays : Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = _vertices
		arrays[Mesh.ARRAY_NORMAL] = _normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mesh_instance.mesh = mesh
	if line_material != null:
		_mesh_instance.material_override = line_material
	else:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = line_color
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh_instance.material_override = material
	if project_to_surface and (_space == null or _misses > 0):
		push_warning("Polar grid: %d samples missed terrain (or physics space is unavailable). Fallback applied; check collision layers and rebuild when ready." % _misses)
	_samples.clear()
	_space = null

# Sample data: world position, world normal, and whether this point may be drawn.
func _sample(world_point : Vector3) -> Dictionary:
	var key : Vector3 = world_point.snapped(Vector3.ONE * 0.00001)
	if _samples.has(key):
		return _samples[key]
	var sample : Dictionary = {"position": world_point, "normal": _up, "valid": true}
	if project_to_surface:
		var hit : Dictionary = {}
		if _space != null:
			var query := PhysicsRayQueryParameters3D.create(world_point + _up * maxf(raycast_height, 0.0), world_point - _up * maxf(raycast_depth, 0.0), terrain_collision_mask)
			hit = _space.intersect_ray(query)
		if not hit.is_empty():
			var normal : Vector3 = hit["normal"]
			sample["position"] = hit["position"] + normal * surface_offset
			sample["normal"] = normal
		else:
			_misses += 1
			sample["valid"] = raycast_fallback == RaycastFallback.PLANAR
	else:
		sample["position"] = world_point + _up * surface_offset
	_samples[key] = sample
	return sample

func _append_ribbon(points : PackedVector3Array, closed : bool) -> void:
	var centers : Array[Dictionary] = []
	for point : Vector3 in points:
		centers.append(_sample(global_transform * point))
	var left : Array[Dictionary] = []
	var right : Array[Dictionary] = []
	for i : int in range(points.size()):
		var previous : int = maxi(i - 1, 0)
		var next : int = mini(i + 1, points.size() - 1)
		if closed and (i == 0 or i == points.size() - 1):
			previous = points.size() - 2
			next = 1
		var tangent : Vector3 = centers[next]["position"] - centers[previous]["position"]
		var normal : Vector3 = centers[i]["normal"]
		var side : Vector3 = tangent.cross(normal).normalized() * line_thickness * 0.5
		var center : Vector3 = centers[i]["position"]
		# Offset in world space for constant thickness, then project both edges.
		if project_to_surface and centers[i]["valid"]:
			left.append(_sample(center - side))
			right.append(_sample(center + side))
		else:
			left.append({"position": center - side, "normal": normal, "valid": centers[i]["valid"]})
			right.append({"position": center + side, "normal": normal, "valid": centers[i]["valid"]})
	for i : int in range(points.size() - 1):
		if not centers[i]["valid"] or not centers[i + 1]["valid"] or not left[i]["valid"] or not right[i]["valid"] or not left[i + 1]["valid"] or not right[i + 1]["valid"]:
			continue
		_triangle(left[i], right[i], left[i + 1])
		_triangle(right[i], right[i + 1], left[i + 1])

func _triangle(a : Dictionary, b : Dictionary, c : Dictionary) -> void:
	var pa : Vector3 = a["position"]
	var pb : Vector3 = b["position"]
	var pc : Vector3 = c["position"]
	var face : Vector3 = (pb - pa).cross(pc - pa)
	if face.length_squared() < 0.000000000001:
		return
	var corners : Array[Dictionary] = [a, b, c]
	# Godot front faces are clockwise; preserve top visibility with custom materials.
	if face.dot(a["normal"] + b["normal"] + c["normal"]) > 0.0:
		corners = [a, c, b]
	for corner : Dictionary in corners:
		_vertices.append(_inverse * corner["position"])
		_normals.append((global_transform.basis.transposed() * (corner["normal"] as Vector3)).normalized())
