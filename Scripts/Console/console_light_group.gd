extends Node3D

class_name ConsoleLightGroup

func set_count(n : int) -> void:
	var lit : int = 0
	for child in get_children():
		if child is ConsoleLight:
			if lit < n:
				child.set_on()
				lit += 1
			else:
				child.set_off()
