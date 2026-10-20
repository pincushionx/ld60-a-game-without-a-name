class_name Util

## Returns the given rotation normalized to the range [0, 360)
static func sanitize_rotation(rotation: float) -> float:
	rotation = fmod(rotation, 360)
	if rotation < 0:
		rotation += 360

	return rotation

## Adds two rotations and returns the result normalized to [0, 360)
static func add_rotations(rotation_a: float, rotation_b: float) -> float:
	return sanitize_rotation(rotation_a + rotation_b)

static func get_rotation_difference(start_rotation: float, end_rotation: float) -> float:
	start_rotation = sanitize_rotation(start_rotation)
	end_rotation = sanitize_rotation(end_rotation)

	var diff : float
	
	if end_rotation > start_rotation:
		diff = end_rotation - start_rotation
		if diff > 180:
			diff = 360 - diff
			diff *= -1
	else:
		diff = start_rotation - end_rotation
		if diff > 180:
			diff = 360 - diff
		else:
			diff *= -1

	return diff


## Returns the shortest difference in degrees between two rotations
static func get_forward_rotation_difference(start_rotation: float, end_rotation: float) -> float:
	start_rotation = sanitize_rotation(start_rotation)
	end_rotation = sanitize_rotation(end_rotation)

	if start_rotation > end_rotation:
		return (start_rotation+360 - end_rotation)
	return end_rotation - start_rotation
		
	#if start_rotation < end_rotation:
		#return sanitize_rotation(start_rotation+360 - end_rotation* -1)
#
	#return sanitize_rotation(end_rotation - start_rotation)

## Returns the shortest difference in degrees between two rotations
static func get_shortest_rotation_difference(start_rotation: float, end_rotation: float) -> float:
	start_rotation = sanitize_rotation(start_rotation)
	end_rotation = sanitize_rotation(end_rotation)

	var diff = abs(end_rotation - start_rotation)
	if diff > 180:
		diff = 360 - diff

	return diff

#static func get_shortest_direction(start_rotation: float, end_rotation: float) -> float:
