extends Node3D

class_name Gun

signal elevation_changed(gun : Gun, elevation : float)
signal bearing_changed(gun : Gun, bearing : float)
signal propellant_changed(gun : Gun, propellant : float)
signal shot_fired(gun : Gun)
signal shot_complete(gun : Gun, projectile : Projectile, enemy_hit : Enemy) # The projectile landed


var projectile_prefab : PackedScene = preload("res://Prefab/projectile.tscn")


var model : Node3D
var projectile_spawn : Marker3D
var seat : Marker3D
var animation_player : AnimationPlayer

@export_range(0.1, 60.0) var aim_response : float = 12.0

var elevation_range : Vector2 = Vector2(0, 75)
var bearing_range : Vector2 = Vector2(-85, 85)
var propellant_range : Vector2 = Vector2(5, 25)

var initial_elevation : float = 0
var initial_bearing : float = 0
var initial_propellant : float = 10

var target_elevation : float = 0
var target_bearing : float = 0
var propellant : float = 0

var ammo_per_turn : int = 3
var ammo_remaining : int = 0

func _enter_tree() -> void:
	model = $Model
	projectile_spawn = $Model/ProjectileSpawn
	seat = $Model/Seat
	animation_player = $AnimationPlayer

func _process(delta: float) -> void:
	var weight : float = 1.0 - exp(-aim_response * delta)
	model.rotation.x = lerp_angle(model.rotation.x, deg_to_rad(target_elevation), weight)
	model.rotation.y = lerp_angle(model.rotation.y, deg_to_rad(target_bearing), weight)

func reload_turn() -> void:
	ammo_remaining = ammo_per_turn

func fire() -> bool:
	if ammo_remaining <= 0:
		return false

	var projectile : Projectile = projectile_prefab.instantiate()
	add_child(projectile)

	var direction := -projectile_spawn.global_transform.basis.z
	projectile.launch(
		projectile_spawn.global_position,
		direction * propellant,
		self
	)
	
	AudioManager.PlayEffect(self, "gunfire")
	animation_player.play("fire")
	
	ammo_remaining -= 1
	projectile.flight_finished.connect(_on_projectile_flight_finished)
	shot_fired.emit(self)
	return true

func _on_projectile_flight_finished(firing_gun : Gun, projectile : Projectile, enemy_hit : Enemy) -> void:
	shot_complete.emit(firing_gun, projectile, enemy_hit)

func set_elevation(v : float) -> void:
	target_elevation = clampf(v, elevation_range.x, elevation_range.y)
	emit_signal("elevation_changed", self, target_elevation)

# Adds v to elevation. Returns true if elevation at upper or lower limit
func add_elevation(v : float) -> bool:
	set_elevation(target_elevation + v)
	return target_elevation == elevation_range.x || target_elevation == elevation_range.y

func set_bearing(v : float) -> void:
	target_bearing = clampf(v, bearing_range.x, bearing_range.y)
	emit_signal("bearing_changed", self, target_bearing)

# Adds v to bearing. Returns true if bearing at upper or lower limit
func add_bearing(v : float) -> bool:
	set_bearing(target_bearing - v)
	return target_bearing == bearing_range.x || target_bearing == bearing_range.y

func set_propellant(v : float) -> void:
	propellant = clampf(v, propellant_range.x, propellant_range.y)
	emit_signal("propellant_changed", self, propellant)

# Adds v to propellant. Returns true if propellant at upper or lower limit
func add_propellant(v : float) -> bool:
	set_propellant(propellant + v)
	return propellant == propellant_range.x || propellant == propellant_range.y

func reset() -> void:
	set_elevation(initial_elevation)
	set_bearing(initial_bearing)
	set_propellant(initial_propellant)
