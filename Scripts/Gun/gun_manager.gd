extends Node3D

class_name GunManager

signal active_gun_elevation_changed(gun : Gun, elevation : float)
signal active_gun_bearing_changed(gun : Gun, bearing : float)
signal active_gun_propellant_changed(gun : Gun, propellant : float)
signal active_gun_shot_fired(gun : Gun)
signal active_gun_shot_complete(gun : Gun, projectile : Projectile, enemy_hit : Enemy)

var current_gun : Gun

func _enter_tree() -> void:
	Globals.guns = self

func _ready() -> void:
	change_gun($Gun)

func fire_current_gun() -> bool:
	if current_gun == null:
		return false
	current_gun.fire()
	return true

func get_current_gun_ammo_remaining() -> int:
	if current_gun == null:
		return 0
	return current_gun.ammo_remaining

func change_gun(gun : Gun) -> void:
	if current_gun != null:
		current_gun.disconnect("elevation_changed", _on_active_gun_elevation_changed)
		current_gun.disconnect("bearing_changed", _on_active_gun_bearing_changed)
		current_gun.disconnect("propellant_changed", _on_active_gun_propellant_changed)
		current_gun.disconnect("shot_fired", _on_active_gun_shot_fired)
		current_gun.disconnect("shot_complete", _on_active_gun_shot_complete)
	current_gun = gun
	if current_gun != null:
		Globals.player.sit(current_gun)
		current_gun.connect("elevation_changed", _on_active_gun_elevation_changed)
		current_gun.connect("bearing_changed", _on_active_gun_bearing_changed)
		current_gun.connect("propellant_changed", _on_active_gun_propellant_changed)
		current_gun.connect("shot_fired", _on_active_gun_shot_fired)
		current_gun.connect("shot_complete", _on_active_gun_shot_complete)
	else:
		# Player is leaving gun.
		pass

func _on_active_gun_elevation_changed(gun : Gun, elevation : float) -> void:
	emit_signal("active_gun_elevation_changed", gun, elevation)

func _on_active_gun_bearing_changed(gun : Gun, bearing : float) -> void:
	emit_signal("active_gun_bearing_changed", gun, bearing)

func _on_active_gun_propellant_changed(gun : Gun, propellant : float) -> void:
	emit_signal("active_gun_propellant_changed", gun, propellant)

func _on_active_gun_shot_fired(gun : Gun) -> void:
	emit_signal("active_gun_shot_fired", gun)

func _on_active_gun_shot_complete(gun : Gun, projectile : Projectile, enemy_hit : Enemy) -> void:
	emit_signal("active_gun_shot_complete", gun, projectile, enemy_hit)
