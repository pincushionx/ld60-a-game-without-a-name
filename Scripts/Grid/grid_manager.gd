@tool
extends Node
class_name GridManager

@export_range(1, 100, 1) var ring_count : int = 8:
	set(value):
		ring_count = value
		_configure_renderer()
@export_range(1, 100, 1) var sector_count : int = 16:
	set(value):
		sector_count = value
		_configure_renderer()
@export var inner_radius : float = 5.0:
	set(value):
		inner_radius = value
		_configure_renderer()
@export var ring_width : float = 3.0:
	set(value):
		ring_width = value
		_configure_renderer()
@export_range(1.0, 360.0, 1.0) var arc_degrees : float = 180.0:
	set(value):
		arc_degrees = value
		_configure_renderer()
@export_range(1, 32, 1) var subdivisions_per_sector : int = 4:
	set(value):
		subdivisions_per_sector = value
		_configure_renderer()

func _enter_tree() -> void:
	Globals.grid = self
	_configure_renderer()

func _configure_renderer() -> void:
	if not is_inside_tree():
		return
	# Keep this untyped as PolarGridRenderer preloads the grid mathematics here.
	var renderer : Node = get_node_or_null("PolarGridRenderer")
	if renderer == null:
		return
	for setting : String in ["ring_count", "sector_count", "inner_radius", "ring_width", "arc_degrees", "subdivisions_per_sector"]:
		renderer.set(setting, get(setting))

const INVALID_CELL : Vector2i = Vector2i(-1, -1)
const EPSILON : float = 0.00001

func is_valid_cell(cell : Vector2i) -> bool:
	return cell.x >= 0 and cell.x < ring_count and cell.y >= 0 and cell.y < sector_count

func get_ring_inner_radius(ring : int) -> float:
	return inner_radius + ring * ring_width

func get_ring_outer_radius(ring : int) -> float:
	return get_ring_inner_radius(ring + 1)

# Radians: zero faces -Z, negative angles face left (-X).
func get_sector_start_angle(sector : int) -> float:
	return deg_to_rad(arc_degrees) * (float(sector) / sector_count - 0.5)

func get_sector_end_angle(sector : int) -> float:
	return get_sector_start_angle(sector + 1)

func cell_to_local(cell : Vector2i, offset : Vector2) -> Vector3:
	var angle : float = get_sector_start_angle(cell.y) + offset.x * deg_to_rad(arc_degrees) / sector_count
	var radius : float = get_ring_inner_radius(cell.x) + offset.y * ring_width
	return Vector3(sin(angle) * radius, 0.0, -cos(angle) * radius)

func get_random_cell_position(cell : Vector2i) -> Vector3:
	var rx : float = randf_range(0.1, 0.9)
	var ry : float = randf_range(0.1, 0.9)
	return cell_to_local(cell, Vector2(rx, ry))

func get_cell_center(cell : Vector2i) -> Vector3:
	return cell_to_local(cell, Vector2(0.5, 0.5))

# Inner-left, outer-left, outer-right, inner-right; arcs connect the corners.
func get_cell_corners(cell : Vector2i) -> PackedVector3Array:
	var corners := PackedVector3Array()
	for offset : Vector2 in [Vector2.ZERO, Vector2(0, 1), Vector2.ONE, Vector2(1, 0)]:
		corners.append(cell_to_local(cell, offset))
	return corners

func _angular_fraction(position : Vector3) -> float:
	var angle : float = atan2(position.x, -position.z)
	if arc_degrees == 360.0:
		angle = wrapf(angle, -PI, PI)
	return (angle + deg_to_rad(arc_degrees) * 0.5) / deg_to_rad(arc_degrees)

func local_to_cell(position : Vector3) -> Vector2i:
	if inner_radius < 0.0 or ring_width <= 0.0 or ring_count <= 0 or sector_count <= 0 or arc_degrees <= 0.0 or arc_degrees > 360.0:
		return INVALID_CELL
	var radius : float = Vector2(position.x, position.z).length()
	var radial : float = (radius - inner_radius) / ring_width
	var angular : float = _angular_fraction(position) * sector_count
	# The origin belongs to sector 0 when the central hole is disabled.
	if radius <= EPSILON and inner_radius == 0.0:
		angular = 0.0
	if radial < -EPSILON or radial > ring_count + EPSILON or angular < -EPSILON or angular > sector_count + EPSILON:
		return INVALID_CELL
	# Snap near internal boundaries; final boundaries belong to the last cell.
	if absf(radial - roundf(radial)) <= EPSILON:
		radial = roundf(radial)
	if absf(angular - roundf(angular)) <= EPSILON:
		angular = roundf(angular)
	return Vector2i(clampi(floori(radial), 0, ring_count - 1), clampi(floori(angular), 0, sector_count - 1))

func get_cell_offset(position : Vector3, cell : Vector2i) -> Vector2:
	var angular : float = _angular_fraction(position) * sector_count
	# The full-circle seam is also the end of the final sector.
	if arc_degrees == 360.0 and cell.y == sector_count - 1 and angular < EPSILON:
		angular = float(sector_count)
	var radial : float = (Vector2(position.x, position.z).length() - get_ring_inner_radius(cell.x)) / ring_width
	return Vector2(clampf(angular - cell.y, 0.0, 1.0), clampf(radial, 0.0, 1.0))
