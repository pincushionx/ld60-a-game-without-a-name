extends Node3D

class_name Player

var player_character : BasicFirstPersonPlayer
@export_range(0.0, 180.0) var aim_speed_degrees : float = 30.0
var scanner : Scanner

var is_paused : bool = false

func _enter_tree() -> void:
	Globals.player = self
	
	player_character = $BasicFirstPersonPlayer
	scanner = $BasicFirstPersonPlayer/Camera3D/Scanner

func _process(delta: float) -> void:
	if is_paused:
		return
		
	var aim_step : float = aim_speed_degrees * delta

	if player_character._seated:
		if Input.is_action_pressed("Left"):
			Globals.guns.current_gun.add_bearing(-aim_step)
		elif Input.is_action_pressed("Right"):
			Globals.guns.current_gun.add_bearing(aim_step)
		elif Input.is_action_pressed("Forward"):
			Globals.guns.current_gun.add_elevation(aim_step)
		elif Input.is_action_pressed("Backward"):
			Globals.guns.current_gun.add_elevation(-aim_step)
		elif Input.is_action_pressed("Propellant_Up"):
			Globals.guns.current_gun.add_propellant(-delta * 10.0)
		elif Input.is_action_pressed("Propellant_Down"):
			Globals.guns.current_gun.add_propellant(delta * 10.0)
		

	
func _input(event: InputEvent) -> void:

	if is_paused:
		return

	if player_character._seated:
		
		if Globals.waves.is_player_turn:
		
			if scanner.CurrentTarget is ConsoleButton:
				if event.is_action_pressed("Interact"):
					Globals.waves.end_turn()
			else:
				if event.is_action_pressed("Interact"):
					Globals.guns.fire_current_gun()
				elif event.is_action_pressed("Fire"):
					Globals.guns.fire_current_gun()

			#if event.is_action_pressed("Cancel"):
				#player_character.sit_up()


	#if event.is_action_pressed("Interact"):
		#if scanner.CurrentTarget is Gun:
			#var gun : Gun = scanner.CurrentTarget
			#Globals.guns.change_gun(gun)
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			Globals.guns.current_gun.add_propellant(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Globals.guns.current_gun.add_propellant(-1)


func sit(gun : Gun) -> void:
	player_character.sit_down(gun.seat)
	
