extends Node3D

class_name EnemyManager

signal advance_finished()

var enemy_prefab : PackedScene = preload("res://Prefab/enemy.tscn")

var is_advancing : bool = false

func _enter_tree() -> void:
	Globals.enemies = self

func create_enemy(grid_pos : Vector2i) -> void:
	var enemy : Enemy = enemy_prefab.instantiate()
	
	add_child(enemy)

	enemy.move_to_immediately(Globals.grid.get_random_cell_position(grid_pos))
	enemy.navigation_finished.connect(_on_enemy_navigation_finished)

func _on_enemy_navigation_finished(_enemy : Enemy) -> void:
	_check_advance_finished()

func _physics_process(_delta : float) -> void:
	if is_advancing:
		_check_advance_finished()

func _check_advance_finished() -> void:
	if not is_advancing:
		return
	for child in get_children():
		if child is Enemy and not child.is_queued_for_deletion() and child._moving:
			return
	is_advancing = false
	advance_finished.emit()

func advance_all() -> void:
	is_advancing = true
	for child in get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			advance_enemy(child)
	_check_advance_finished()

func advance_enemy(e : Enemy) -> void:
	e.last_move_end_time = -1
	var grid_pos : Vector2i = Globals.grid.local_to_cell(e.global_position)
	grid_pos.x -= 1
	if grid_pos.x < 0:
		Logs.Debug("Enemy %s reached the base" % e.name)
		Globals.scene.show_lose_screen()
		e.queue_free()
	else:
		var pos : Vector3 = Globals.grid.get_random_cell_position(grid_pos)
		e.move_to(pos)
	
	is_advancing = true
