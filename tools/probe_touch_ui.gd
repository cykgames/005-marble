extends Node
## Regression probe for the touch UI pass:
##   1. JUMP button meets the 48dp target on a 1080px-wide phone
##      (stretch scale 1080/1280), both axes >= 120 device px,
##   2. tip_touch wiring keeps desktop wording when no real touchscreen is
##      present (headless/desktop), i.e. desktop behaviour is unchanged.
## Run: godot --headless --path . res://tools/probe_touch_ui.tscn

func _ready() -> void:
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

	for c in get_children():
		c.free()
	if failures.is_empty():
		print("PROBE PASS: JUMP >= 120px both axes at 1080 wide; desktop tips unchanged")
		get_tree().quit(0)
	else:
		for f in failures:
			printerr("PROBE FAIL: ", f)
		get_tree().quit(1)