extends Node
## Regression probe for the touch UI pass:
##   1. JUMP button meets the 48dp target on a 1080px-wide phone
##      (stretch scale 1080/1280), both axes >= 120 device px,
##   2. tip_touch wiring keeps desktop wording when no real touchscreen is
##      present (headless/desktop), i.e. desktop behaviour is unchanged.
##   3. Pause chip: invisible hit >= 120 device px both axes, clear of JUMP
##      and the clock, face inside the hit; pressing it drives the real
##      "pause" action into the real PauseMenu (pause/resume round trip),
##      and a held stick/jump is released when the tree pauses.
## Run: godot --headless --path . res://tools/probe_touch_ui.tscn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("touch signals: is_touchscreen_available=%s feature_touchscreen=%s android=%s" % [
		DisplayServer.is_touchscreen_available(),
		DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN),
		OS.has_feature("android")])
	var failures: Array[String] = []
	var tc := TouchControls.new()
	add_child(tc)
	var button := tc._action_button("JUMP", &"jump")
	var scale := 1080.0 / 1280.0
	var device := button.custom_minimum_size * scale
	print("JUMP min size design=%s device@1080=%s" % [
		str(button.custom_minimum_size), str(device)])
	if device.x < 120.0 or device.y < 120.0:
		failures.append("JUMP below 48dp: %s" % str(device))

	var parent := Node3D.new()
	add_child(parent)
	var builder := LevelBuilder.new(parent,
		preload("res://resources/biomes/meadow.tres"))
	var def: LevelDef = load("res://levels/defs/first_roll.gd").new()
	def.build(builder)
	if builder.tips.is_empty():
		failures.append("first_roll built no tips")
	else:
		var first: String = builder.tips[0].text
		print("first tip (headless/desktop): ", first)
		if first != "Drag on the left half of the screen to roll. WASD works too.":
			failures.append("desktop tip wording changed: %s" % first)
	var zone := builder.tip_touch(Vector3.ZERO, "touch words", "desktop words")
	if zone.text != "desktop words":
		failures.append("tip_touch desktop branch wrong: %s" % zone.text)

	# Thumb-zone placement: measure the real HUD tip pill (longest touch
	# tip) against the JUMP column rect at phone design size 1280x2773
	# (1080x2340 device / 0.84375 stretch scale). They must not intersect.
	var hud := Hud.new()
	add_child(hud)
	hud.size = Vector2(1280, 2773)
	hud.show_tip("With DOUBLE JUMP running, tap JUMP again in mid-air.")
	await get_tree().process_frame
	await get_tree().process_frame
	var tip_rect: Rect2 = hud._tip_panel.get_global_rect()
	var jump_size := button.custom_minimum_size
	var btn_rect := Rect2(
		Vector2(1280.0 - 30.0 - jump_size.x, 2773.0 - 120.0 - jump_size.y), jump_size)
	print("tip rect=%s jump rect=%s" % [str(tip_rect), str(btn_rect)])
	if tip_rect.intersects(btn_rect):
		failures.append("tip pill overlaps JUMP button")

	# Pause chip: build it directly (headless has no touchscreen, so
	# TouchControls._ready skips the touch branch). The hit rect is measured
	# at phone design size, then scaled to device px like JUMP above.
	tc.size = Vector2(1280, 2773)
	tc.process_mode = Node.PROCESS_MODE_PAUSABLE
	tc._build_pause_chip()
	var pm = load("res://ui/pause_menu.tscn").instantiate()
	add_child(pm)
	await get_tree().process_frame
	var hit_rect: Rect2 = tc._pause_hit.get_global_rect()
	var face_rect: Rect2 = tc._pause_face.get_global_rect()
	var hit_device := hit_rect.size * scale
	print("pause hit rect=%s device@1080=%s face=%s" % [
		str(hit_rect), str(hit_device), str(face_rect)])
	if hit_device.x < 120.0 or hit_device.y < 120.0:
		failures.append("pause hit below 48dp: %s" % str(hit_device))
	if hit_rect.intersects(btn_rect):
		failures.append("pause hit overlaps JUMP button")
	if not hit_rect.encloses(face_rect):
		failures.append("pause face outside its hit rect")
	if hit_rect.intersects(hud._clock.get_global_rect()):
		failures.append("pause hit overlaps the clock")
	# Functional: a held stick + jump, then the chip's action press must
	# pause the tree through the real PauseMenu and drop the held actions.
	Input.action_press(&"move_forward", 1.0)
	Input.action_press(&"jump")
	tc._on_pause_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	if not get_tree().paused or not pm._open:
		failures.append("pause chip did not pause via the pause action")
	if Input.is_action_pressed(&"move_forward") or Input.is_action_pressed(&"jump"):
		failures.append("held stick/jump not released on pause")
	pm.resume()
	await get_tree().process_frame
	if get_tree().paused or pm._open:
		failures.append("resume did not unpause")
	# The action toggles: a second chip press pauses, a third resumes.
	tc._on_pause_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	tc._on_pause_pressed()
	await get_tree().process_frame
	await get_tree().process_frame
	if get_tree().paused:
		failures.append("pause action toggle did not resume")

	for c in get_children():
		c.free()
	if failures.is_empty():
		print("PROBE PASS: JUMP >= 120px both axes at 1080 wide; desktop tips unchanged; pause chip wired")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("PROBE FAIL: ", f)
		get_tree().quit(1)