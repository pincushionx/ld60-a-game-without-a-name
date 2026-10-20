extends Node

signal hour_changed_event

const TIME_SPEED : float = 300.0 # vs real time. >1.0 is faster than realk time
const HOUR : float = 60 * 60 / TIME_SPEED
const start_seconds : float = HOUR * 6 # 6hrs
var PlayTimeElapsed : float = start_seconds
var IsGameplayPaused : bool = false;




var hours_float : float
var hours : int
var minutes : int

var prev_hours : int = -1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !IsGameplayPaused:
		var total_minutes : float = PlayTimeElapsed * TIME_SPEED / 60.0
		hours_float = fmod(total_minutes / 60.0, 24.0)
		hours = floori(total_minutes / 60.0) % 24
		minutes = floori(total_minutes) % 60

		if hours != prev_hours:
			hour_changed_event.emit()
			prev_hours = hours

		var nighttime_modifier : float = 1.0
		if hours >= 18 || hours < 6:
			nighttime_modifier *= 12.0
		PlayTimeElapsed += delta * nighttime_modifier

func PlayTimeSince(since : float):
	return PlayTimeElapsed - since
