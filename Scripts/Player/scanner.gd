extends Node3D

class_name Scanner

const SCAN_DISTANCE : float = 250.0

var CurrentTarget : Node
var CurrentTargetCollider : Node
var TargetPosition : Vector3
var TargetGridPosition : Vector2i

@onready var _camera  : Node3D

func _ready() -> void:
	_camera = get_parent()

func _physics_process(_delta):
	_doScan()

func _doScan():
	_camera = get_viewport().get_camera_3d()
	if _camera == null:
		_reset()
		return
	
	var mouse_pos = get_viewport().get_mouse_position() # 1. Get 2D position
	var _scanFrom = _camera.project_ray_origin(mouse_pos)       # 2. Origin point
	var _scanTo = _scanFrom + _camera.project_ray_normal(mouse_pos) * SCAN_DISTANCE # 3. Target point

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(_scanFrom, _scanTo)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	#query.collision_mask = 0x3
	#query.exclude = [Globals.player.player_character.get_rid()]

	var result = space_state.intersect_ray(query)
	
	if !result.is_empty():
		# Regardless of the result. Shrink the size of the ray to what was found
		#var distanceToHit : float = Vector2(_scanFrom.x, _scanFrom.z).distance_to(Vector2(result.position.x, result.position.z))	
		var collider = result.collider;
		if collider == CurrentTargetCollider:
			# do nothing until target changes
			
			# ... maybe the position changed
			TargetPosition = result.position
			TargetGridPosition = Vector2i(floori(result.position.x), floori(result.position.z))
			return

		# Store what was hit
		CurrentTargetCollider = collider
		TargetPosition = result.position
		TargetGridPosition = Vector2i(floori(result.position.x), floori(result.position.z))

		# Get real target
		CurrentTarget = collider
		if CurrentTarget is GunChildCollider:
			CurrentTarget = CurrentTarget.get_root()

		# Track components
		if CurrentTarget != null:
			if !CurrentTarget.is_connected("tree_exiting", _on_target_tree_exiting):
				CurrentTarget.connect("tree_exiting", _on_target_tree_exiting)

	else:
		_reset()

func _on_target_tree_exiting() -> void:
	if CurrentTarget != null:
		CurrentTarget.disconnect("tree_exiting", _on_target_tree_exiting)
		_reset()

func _reset() -> void:
	CurrentTargetCollider = null
	CurrentTarget = null

	
