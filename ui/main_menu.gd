extends Control
## Title screen.

const BUTTON_WIDTH := 340.0
const BUTTON_GAP := 12
## Touch-target floor for portrait phones: 150 design px ≈ 127 device px at
## 1080 wide (base 1280x720 + stretch "expand" => scale 0.84375). The fleet
## standard is >= 120 device px (48 dp on the A54).
const TOUCH_BUTTON_HEIGHT := 150.0


func _ready() -> void:
	var portrait := get_viewport_rect().size.y > get_viewport_rect().size.x
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	if portrait:
		# Drop the menu into the lower two thirds so the buttons sit in the
		# thumb zone instead of mid-screen. Landscape keeps the old centering
		# (tall buttons would overflow a 720-high window).
		center.anchor_top = 0.30
		center.anchor_bottom = 0.94
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := Ui.column(4)
	center.add_child(box)
	box.add_child(Ui.label("COURSES IN THE SKY AND BEYOND", &"CaptionLabel",
		HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(Ui.label("MARBLE RUNNER", &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(Ui.rule())
	box.add_child(Ui.label("Roll. Jump. Collect every gem. Beat the clock.", &"HintLabel",
		HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(Ui.gap(28))

	# "Play" always means the next thing worth playing; "Levels" is for choosing.
	var next := GameState.next_unbeaten()
	var play := Ui.button("Play" if next == 0 else "Continue   Level %d" % (next + 1),
		BUTTON_WIDTH, Icon.Kind.PLAY, &"PrimaryButton")
	var half := (BUTTON_WIDTH - BUTTON_GAP) / 2.0
	var levels := Ui.button("Levels", half, Icon.Kind.LEVELS)
	var shop := Ui.button("Shop", half, Icon.Kind.SHOP)
	var quit := Ui.button("Quit", BUTTON_WIDTH, Icon.Kind.QUIT, &"GhostButton")
	if portrait:
		# Whole button rect is the tap target; make it thumb-sized.
		for b: Button in [play, levels, shop, quit]:
			b.custom_minimum_size.y = TOUCH_BUTTON_HEIGHT
			b.add_theme_font_size_override("font_size", 24)
	play.pressed.connect(SceneManager.continue_game)
	levels.pressed.connect(SceneManager.goto_level_select)
	shop.pressed.connect(SceneManager.goto_shop)
	quit.pressed.connect(SceneManager.quit_game)
	# A browser tab cannot be quit from inside the page.
	quit.visible = not OS.has_feature("web")
	var pair := Ui.row(BUTTON_GAP)
	pair.add_child(levels)
	pair.add_child(shop)
	var buttons := Ui.column(BUTTON_GAP)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_child(play)
	buttons.add_child(pair)
	buttons.add_child(quit)
	box.add_child(buttons)
	box.add_child(Ui.gap(10))
	box.add_child(Ui.label("by cykbot4", &"CaptionLabel", HORIZONTAL_ALIGNMENT_CENTER))

	var purse := Ui.row(10)
	purse.add_child(StatPill.new(Icon.Kind.STAR, Icon.GOLD, "%d / %d" % [
		GameState.total_stars(), LevelCatalog.count() * StarRow.COUNT]))
	purse.add_child(StatPill.new(Icon.Kind.DIAMOND, Icon.DIAMOND_WHITE, "%d / %d" % [
		GameState.total_secrets(), LevelCatalog.count()]))
	purse.add_child(StatPill.new(Icon.Kind.GEM, Icon.GEM_BLUE, str(GameState.gems)))
	add_child(purse)
	Ui.pin(purse, Control.PRESET_TOP_RIGHT, Vector2(24, 20))

	if DisplayServer.is_touchscreen_available():
		# Touch-first wording replaces the keyboard hint row on phones.
		var hint := Ui.label("Drag the left side to roll · Tap JUMP to jump",
			&"HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
		add_child(hint)
		Ui.pin(hint, Control.PRESET_CENTER_BOTTOM, Vector2(0, 30))
	else:
		var keys := Ui.row(34)
		keys.add_child(Ui.key_hint(["W", "A", "S", "D"], "ROLL"))
		keys.add_child(Ui.key_hint(["SPACE"], "JUMP"))
		keys.add_child(Ui.key_hint(["Q", "E"], "CAMERA"))
		keys.add_child(Ui.key_hint(["ESC"], "PAUSE"))
		add_child(keys)
		Ui.pin(keys, Control.PRESET_CENTER_BOTTOM, Vector2(0, 30))

	Ui.cascade([play, pair, quit], 0.1)
	# Makes the menu playable with the keyboard alone.
	play.grab_focus()
