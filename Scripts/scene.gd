extends Node3D

class_name Scene

var tutorial_screen : Control
var lose_screen : Control
var lose_screen_score : Label

var is_tutorial : bool = true
var is_lose : bool = false
var _particles_ready : bool = false

func _enter_tree() -> void:
	Globals.scene = self
	tutorial_screen = $CanvasLayer/Briefing
	lose_screen = $CanvasLayer/LoseScreen
	lose_screen_score = $CanvasLayer/LoseScreen/Score

func _ready() -> void:
	tutorial_screen.show()
	lose_screen.hide()
	Globals.player.is_paused = true
	Globals.player.player_character.Pause()
	_prewarm_particles.call_deferred()

func _prewarm_particles() -> void:
	# Headless tests have no rendered frames to wait for.
	if DisplayServer.get_name() == "headless":
		_particles_ready = true
		return
	var camera : Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		_particles_ready = true
		return
	var cover := CanvasLayer.new()
	cover.layer = 100
	add_child(cover)
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_child(background)
	var label := Label.new()
	label.text = "Preparing effects..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(label)

	var effects : Array[GPUParticles3D] = []
	for prefab : PackedScene in [Globals.waves.particle_hit_prefab, Globals.waves.particle_miss_prefab, preload("res://Prefab/smoke.tscn")]:
		effects.append(prefab.instantiate())
	# Enemy exhaust has its own material; warm that exact variant too.
	for enemy in Globals.enemies.get_children():
		if enemy is Enemy:
			effects.append(enemy.get_node("Smoke").duplicate())
			break
	for effect in effects:
		effect.position = Vector3(0, 0, -2)
		effect.scale = Vector3.ONE * 0.1
		effect.preprocess = 0.25
		effect.emitting = true
		camera.add_child(effect)
		effect.restart()
	# Compatibility/WebGL compiles on actual drawing, not on preload or hide().
	await get_tree().create_timer(0.25).timeout
	for frame in range(3):
		await RenderingServer.frame_post_draw
	for effect in effects:
		effect.hide()
		effect.queue_free()
	cover.queue_free()
	_particles_ready = true
	
func _input(event: InputEvent) -> void:
	if TimeKeeper.PlayTimeElapsed > 3:
		if _particles_ready and is_tutorial and event is InputEventKey and event.pressed and not event.echo:
			tutorial_screen.hide()
			is_tutorial = false
			Globals.player.is_paused = false
			Globals.player.player_character.Unpause()

func show_lose_screen() -> void:
	Globals.player.is_paused = true
	Globals.player.player_character.Pause()
	lose_screen_score.text = "%s Tanks" % Globals.waves.score
	lose_screen.show()
