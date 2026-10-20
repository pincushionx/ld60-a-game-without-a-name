extends CanvasLayer

var _label : Label
var _elapsed : float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	# Anchors handle viewport resizing; offsets keep a small margin from the edges.
	_label.offset_left = 12
	_label.offset_top = -36
	_label.offset_right = 132
	_label.offset_bottom = -12
	_update_text()

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("FPS") and not event.is_echo():
		visible = not visible
		set_process(visible)
		if visible:
			_update_text()
		get_viewport().set_input_as_handled()

func _process(delta : float) -> void:
	_elapsed += delta
	if _elapsed >= 0.25:
		_elapsed = 0.0
		_update_text()

func _update_text() -> void:
	_label.text = "FPS: %d" % Engine.get_frames_per_second()
