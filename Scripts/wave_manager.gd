extends Node

class_name WaveManager

var is_active : bool = false
var is_player_turn : bool = false

var enemy_launch_times : Array = []
var enemy_launch_index : int = -1

var total_enemies_this_wave : int = 3
var remaining_enemies_this_wave : int = -1

var last_launch_time : float = -1

var particle_container : Node3D
var particle_hit_prefab : PackedScene = preload("res://Prefab/destroy_fire.tscn")
var particle_miss_prefab : PackedScene = preload("res://Prefab/miss_fire.tscn")

var score : int = 0

func _enter_tree() -> void:
	Globals.waves = self
	particle_container = $Particles

func _ready() -> void:
	Globals.enemies.advance_finished.connect(_on_enemy_advance_finished)

	Globals.guns.active_gun_shot_complete.connect(_on_gun_shot_complete)

	is_active = true
	is_player_turn = true
	test_wave()
	Globals.console.update_turn_status()

#func _process(_delta: float) -> void:
	#
	#var launch := get_next_launch()
	#if launch != null:
		#if TimeKeeper.PlayTimeSince(last_launch_time) > launch.delay:
			#launch_next_enemy()
			#last_launch_time = TimeKeeper.PlayTimeElapsed
	#
	#for child in Globals.enemies.get_children():
		#if child is Enemy:
			#if child.last_move_end_time > 0 && TimeKeeper.PlayTimeSince(child.last_move_end_time) > 5.0:
				#child.last_move_end_time = -1
				#Globals.enemies.advance_enemy(child)

func _on_enemy_advance_finished() -> void:
	is_player_turn = true
	Globals.console.update_turn_status()

func test_wave() -> void:
	for i in total_enemies_this_wave:
		var launch : EnemyLaunch = EnemyLaunch.new()
		launch.delay = 5.0
		launch.sector = randf_range(0, Globals.grid.sector_count-1)
		enemy_launch_times.append(launch)
	
	launch_next_enemy()
	Globals.guns.current_gun.reload_turn()

func get_next_launch() -> EnemyLaunch:
	if enemy_launch_index < 0:
		enemy_launch_index = 0

	if enemy_launch_index >= enemy_launch_times.size():
		return null

	return enemy_launch_times[enemy_launch_index]

func launch_next_enemy() -> bool:
	#var launch : EnemyLaunch = get_next_launch()
	#if launch == null:
		#return false
	
	var grid_pos : Vector2i
	grid_pos.x = Globals.grid.ring_count-1
	grid_pos.y = randf_range(0, Globals.grid.sector_count-1)
	Globals.enemies.create_enemy(grid_pos)
	enemy_launch_index += 1
	return true


func end_turn() -> void:
	is_player_turn = false

	Globals.enemies.advance_all()
	
	launch_next_enemy()
	Globals.guns.current_gun.reload_turn()
	
	Globals.console.update_turn_status()
	pass

func end_wave() -> void:
	clear_particles()

func _on_gun_shot_complete(gun : Gun, projectile : Projectile, enemy_hit : Enemy) -> void:
	clear_particles()
	
	var prefab : PackedScene = particle_hit_prefab if is_instance_valid(enemy_hit) else particle_miss_prefab
	var particles : GPUParticles3D = prefab.instantiate()
	# Position the emitter before starting its simulation, including the final shot.
	particles.emitting = false
	particle_container.add_child(particles)
	particles.global_position = projectile.final_position
	particles.restart()
	particles.emitting = true

	if enemy_hit != null:
		score += 1
		Globals.console._update_score()
		
		if get_active_enemy_count() == 0:
			end_turn()
		elif gun.ammo_remaining == 0:
			end_turn()

	elif gun.ammo_remaining == 0:
		end_turn()

func get_active_enemy_count() -> int:
	var count : int = 0
	for child in Globals.enemies.get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			count += 1
	return count

func get_best_sector() -> int:
	var outermost_rings := PackedInt32Array()
	outermost_rings.resize(Globals.grid.sector_count)
	outermost_rings.fill(-1)
	for child in Globals.enemies.get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			var cell : Vector2i = Globals.grid.local_to_cell(child.global_position)
			if Globals.grid.is_valid_cell(cell):
				outermost_rings[cell.y] = maxi(outermost_rings[cell.y], cell.x)

	var sector : int = 0
	var best_ring : int = Globals.grid.ring_count
	var tied_sectors : int = 0
	for candidate in outermost_rings.size():
		var outermost_ring : int = outermost_rings[candidate]
		if outermost_ring < best_ring:
			best_ring = outermost_ring
			sector = candidate
			tied_sectors = 1
		elif outermost_ring == best_ring:
			tied_sectors += 1
			if randi_range(1, tied_sectors) == 1:
				sector = candidate
	return sector

func clear_particles() -> void:
	for child in particle_container.get_children():
		child.queue_free()

class EnemyLaunch:
	var delay : float
	var sector : int
