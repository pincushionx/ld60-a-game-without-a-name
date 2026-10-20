extends Node3D

class_name GunChildCollider

var root : Gun

func _enter_tree() -> void:
	var parent : Node3D

	# Get the root Target
	parent = get_parent()
	while  parent != null:
		if parent is Gun:
			root = parent
			break
		var new_parent : Node = parent.get_parent()
		if new_parent is Node3D:
			parent = new_parent
		else:
			break
	
	if root == null:
		Logs.Error("GunChildCollider %s has no root" % name)

func get_root() -> Gun:
	return root
