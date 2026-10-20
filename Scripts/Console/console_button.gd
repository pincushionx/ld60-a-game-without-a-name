extends Area3D

class_name ConsoleButton

var on_model : Node3D
var off_model : Node3D

func _enter_tree() -> void:
	on_model = $Models/On
	off_model = $Models/Off

func set_on() -> void:
	on_model.show()
	off_model.hide()

func set_off() -> void:
	off_model.show()
	on_model.hide()
