class_name TouchControls
extends Control
## On-screen stick and jump button, shown only on a touchscreen.
##
## The left half of the screen is a floating stick: it appears wherever the
## thumb lands. It drives the same input actions as the keyboard, so nothing
## else in the game knows touch exists.

const STICK_RADIUS := 90.0
const MOVE_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_forward", &"move_back"]
## Pause chip: the visible face stays small, but the real touch target is an
## invisible 166x166 button (140 device px at the 0.84375 portrait scale =
## 50dp at density 450). Same pattern as 001/002/006. It sits below the HUD
## level title + environment pill, which own the very top of the corner.
const PAUSE_HIT := 166.0
const PAUSE_HIT_TOP := 104.0

var _stick_touch: int = -1
var _stick_origin := Vector2.ZERO
var _stick_offset := Vector2.ZERO
var _pause_hit: Button
var _pause_face: Panel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available()
	set_process_input(visible)
	if not visible:
		return
	Ui.apply_phone_theme(self)
	var buttons := Ui.column(14)
	buttons.mouse_filter = Control.MOUSE_FILTER_PASS
	buttons.add_child(_action_button("JUMP", &"jump"))
	add_child(buttons)
	Ui.pin(buttons, Control.PRESET_BOTTOM_RIGHT, Vector2(30, 120))
	_build_pause_chip()


## The pause chip presses the same "pause" action as ESC/P, so the pause
## menu owns the paused state exactly as it does for the keyboard. Nothing
## here reaches into the menu.
func _build_pause_chip() -> void:
	_pause_hit = Button.new()
	_pause_hit.focus_mode = Control.FOCUS_NONE
	for sn: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		_pause_hit.add_theme_stylebox_override(sn, StyleBoxEmpty.new())
	_pause_hit.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_hit.offset_left = -PAUSE_HIT
	_pause_hit.offset_top = PAUSE_HIT_TOP
	_pause_hit.offset_right = 0.0
	_pause_hit.offset_bottom = PAUSE_HIT_TOP + PAUSE_HIT
	_pause_hit.pressed.connect(_on_pause_pressed)
	add_child(_pause_hit)
	_pause_face = Panel.new()
	_pause_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.10, 0.16, 0.82)
	sb.border_color = Color(0.85, 0.92, 1.0, 0.5)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	_pause_face.add_theme_stylebox_override(&"panel", sb)
	_pause_face.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Offsets are relative to the hit button (which starts at PAUSE_HIT_TOP):
	# face lands at screen y 128..184, under the HUD title + environment pill.
	_pause_face.offset_left = -96.0
	_pause_face.offset_top = 24.0
	_pause_face.offset_right = -20.0
	_pause_face.offset_bottom = 80.0
	_pause_hit.add_child(_pause_face)
	var glyph := Icon.new(Icon.Kind.PAUSE, 30.0)
	glyph.set_anchors_preset(Control.PRESET_CENTER)
	glyph.offset_left = -15.0
	glyph.offset_right = 15.0
	glyph.offset_top = -15.0
	glyph.offset_bottom = 15.0
	_pause_face.add_child(glyph)
	_pause_hit.button_down.connect(func() -> void:
		_pause_face.modulate = Color(0.55, 0.85, 1.7))
	_pause_hit.button_up.connect(func() -> void:
		_pause_face.modulate = Color.WHITE)


func _on_pause_pressed() -> void:
	# Input.action_press only sets the polled state -- it does not emit an
	# event (verified headless on 4.7.2). The pause menu listens for the
	# event, so parse a real InputEventAction, the same path ESC/P take.
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)


## While the tree is paused this node receives no input, so a stick finger
## lifted during the pause would never be heard and its move actions would
## stay pressed into the resume. Drop the stick and the jump on the way in.
func _notification(what: int) -> void:
	if what != NOTIFICATION_PAUSED:
		return
	_stick_touch = -1
	_stick_offset = Vector2.ZERO
	_apply_stick()
	Input.action_release(&"jump")
	queue_redraw()


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _stick_touch < 0 and touch.position.x < size.x * 0.5:
			_stick_touch = touch.index
			_stick_origin = touch.position
			_stick_offset = Vector2.ZERO
		elif not touch.pressed and touch.index == _stick_touch:
			_stick_touch = -1
			_stick_offset = Vector2.ZERO
			_apply_stick()
		queue_redraw()
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _stick_touch:
		_stick_offset = (drag.position - _stick_origin).limit_length(STICK_RADIUS)
		_apply_stick()
		queue_redraw()


func _draw() -> void:
	if _stick_touch < 0:
		return
	draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.1))
	draw_circle(_stick_origin + _stick_offset, 34.0, Color(1, 1, 1, 0.35))


func _apply_stick() -> void:
	var value := _stick_offset / STICK_RADIUS
	var strengths := [maxf(0.0, -value.x), maxf(0.0, value.x), maxf(0.0, -value.y), maxf(0.0, value.y)]
	for index in MOVE_ACTIONS.size():
		if strengths[index] > 0.05:
			Input.action_press(MOVE_ACTIONS[index], strengths[index])
		else:
			Input.action_release(MOVE_ACTIONS[index])


func _action_button(text: String, action: StringName) -> Button:
	var button := Ui.button(text, 300.0)
	# Action-button sized, in the same league as 002's J (330 design units):
	# 300 * (1080 / 1280) = 253 device px = 90dp at density 450 (~17mm).
	# The old 168 gave 141.75px = 50.4dp -- the bare minimum touch target,
	# too small to mash comfortably in a jump-heavy game.
	button.custom_minimum_size.y = 300.0
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(Input.action_press.bind(action))
	button.button_up.connect(Input.action_release.bind(action))
	return button
