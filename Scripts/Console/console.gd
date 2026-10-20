extends Node3D

class_name Console

#var end_turn_button : ConsoleButton
var enemy_turn_light : ConsoleLight
var ammo_lights : ConsoleLightGroup
var debug_label : Label3D

var elevation_numbers : ConsoleNumbers
var bearing_numbers : ConsoleNumbers
var propellant_numbers : ConsoleNumbers
var score_numbers : ConsoleNumbers

func _enter_tree() -> void:
	Globals.console = self
	debug_label = $DebugLabel
	#end_turn_button = $EndTurnButton
	enemy_turn_light = $EnemyTurnLight
	ammo_lights = $AmmoLights
	elevation_numbers = $ElevationNumbers
	bearing_numbers = $BearingNumbers
	propellant_numbers = $PropellantNumbers
	score_numbers = $ScoreNumbers

func _ready() -> void:
	Globals.guns.connect("active_gun_elevation_changed", _on_active_gun_elevation_changed)
	Globals.guns.connect("active_gun_bearing_changed", _on_active_gun_bearing_changed)
	Globals.guns.connect("active_gun_propellant_changed", _on_active_gun_propellant_changed)
	
	Globals.guns.active_gun_shot_fired.connect(func(gun : Gun): update_turn_status())
	
	update_turn_status()

	elevation_numbers.target_number = 0
	bearing_numbers.target_number = 0
	propellant_numbers.target_number = 0
	score_numbers.target_number = 0

func update_turn_status() -> void:
	if !Globals.waves.is_active:
		#end_turn_button.set_off()
		enemy_turn_light.set_off()
	elif Globals.waves.is_player_turn:
		#end_turn_button.set_on()
		enemy_turn_light.set_off()
	else:
		#end_turn_button.set_off()
		enemy_turn_light.set_on()

	ammo_lights.set_count(Globals.guns.get_current_gun_ammo_remaining())



func _on_active_gun_elevation_changed(_gun : Gun, _elevation : float) -> void:
	_update_current_gun()

func _on_active_gun_bearing_changed(_gun : Gun, _bearing : float) -> void:
	_update_current_gun()

func _on_active_gun_propellant_changed(_gun : Gun, _propellant : float) -> void:
	_update_current_gun()

func _update_current_gun() -> void:
	if Globals.guns.current_gun != null:
		set_debug_text("Elevation: %.2f\nBearing: %.2f\nPropellant: %.2f" % [Globals.guns.current_gun.target_elevation, Globals.guns.current_gun.target_bearing, Globals.guns.current_gun.propellant])


		elevation_numbers.target_number = floori(Globals.guns.current_gun.target_elevation)
		bearing_numbers.target_number = floori(Globals.guns.current_gun.target_bearing-Globals.guns.current_gun.bearing_range.x)
		propellant_numbers.target_number = floori(Globals.guns.current_gun.propellant)
	else:
		set_debug_text("No active gun")

func _update_score() -> void:
	if Globals.guns.current_gun != null:
		score_numbers.target_number = Globals.waves.score


func set_debug_text(s : String) -> void:
	debug_label.text = s
