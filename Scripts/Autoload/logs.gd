extends Node

enum LOG_LEVEL {
	DEBUG,
	ERROR
}

const LogLevel : LOG_LEVEL = LOG_LEVEL.DEBUG

func Debug(s : String):
	if LogLevel <= LOG_LEVEL.DEBUG:
		var current_time = Time.get_datetime_string_from_system()
		print("D: %s - %s" % [current_time, s])

func Error(s : String):
	if LogLevel <= LOG_LEVEL.ERROR:
		print("E: %s" % s)
