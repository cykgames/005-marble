extends Node
## Headless smoke harness for cykgames 005-marble (Android touch build).
##
## Run:
##   godot --headless --path . res://tools/headless_test.tscn
##
## What it proves:
## 1. Three level defs (indices 1, 7, 33) build through LevelBuilder headless.
## 2. Level 1 "First Roll" is played by a waypoint bot that drives the SAME
##    input actions the on-screen touch stick uses (Input.action_press on
##    move_left/right/forward/back), so the touch input path is exercised.
## 3. At least 60 s of simulated play (and 60 s wall time), with movement and
##    gem/finish progression asserted. Evidence lines are prefixed [SMOKE].
##
## Exit code 0 = pass, 1 = fail. GameState.persist is disabled so the harness
## cannot overwrite a real player's save.

const MIN_SIM_SECONDS := 65.0
const MIN_WALL_SECONDS := 60.0
const MAX_WALL_SECONDS := 180.0
const ATTEMPT_TIMEOUT := 50.0
## Hand-built route for first_roll.gd: gem line 1, corner, gem line 2, ramp,
## the two ledge gems, then the finish pad. (x, z) pairs, floor heights vary.
const ROUTE: Array[Vector2] = [
	Vector2(0, -16),
	Vector2(0, -22),
	Vector2(16, -22),
	Vector2(26, -22),
	Vector2(31, -19),
	Vector2(31, -25),
	Vector2(36, -22),
]
const WAYPOINT_RADIUS := 1.1
const MOVE_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_forward", &"move_back"]

var _phase := "wait"
var _game: Node = null
var _marble: Marble = null
var _waypoint := 0
var _sim_time := 0.0
var _attempt_time := 0.0
var _attempt := 1
var _start_pos := Vector3.ZERO
var _max_dist := 0.0
var _gems_max := 0
var _finished_once := false
var _finish_time := -1.0
var _finish_gems := 0
var _wall_start_ms := 0
var _restart_hold := 0.0


func _ready() -> void:
	_wall_start_ms = Time.get_ticks_msec()
	GameState.persist = false
	print("[SMOKE] engine=%s physics_engine_setting=%s renderer=%s" % [
		Engine.get_version_info().string,
		ProjectSettings.get_setting("physics/3d/physics_engine"),
		ProjectSettings.get_setting("rendering/renderer/rendering_method")])
	_build_level_proofs()
	# Move the harness out of the current-scene slot so SceneManager can swap
	# scenes without freeing it.
	var tree := get_tree()
	tree.current_scene = null
	reparent(tree.root)
	SceneManager.play_level(0)


## Builds three other level defs through the real builder, headless:
## two hand-built (mind_the_gap, thin_ice) and one Trail-based (assembly_line).
func _build_level_proofs() -> void:
	for index in [1, 7, 33]:
		var def: LevelDef = LevelCatalog.at(index)
		var holder := Node3D.new()
		add_child(holder)
		var builder := LevelBuilder.new(holder, def.biome)
		def.build(builder)
		print("[SMOKE] level_build idx=%d id=%s title=\"%s\" nodes=%d gems=%d route_points=%d" % [
			index, def.id, def.title, holder.get_child_count(),
			builder.gems.size(), builder.route.size()])
		holder.queue_free()


func _wall_seconds() -> float:
	return float(Time.get_ticks_msec() - _wall_start_ms) / 1000.0


func _process(delta: float) -> void:
	if _wall_seconds() > MAX_WALL_SECONDS:
		_finish(false, "wall timeout")
		return
	match _phase:
		"wait":
			_wait_for_game()
		"drive":
			_drive(delta)
		"hold":
			# Brief pause on the results card before the next attempt.
			_restart_hold -= delta
			if _restart_hold <= 0.0:
				_attempt += 1
				_waypoint = 0
				_attempt_time = 0.0
				_phase = "wait"
				SceneManager.restart_level()
		"done":
			pass


func _wait_for_game() -> void:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_node("Marble"):
		return
	_game = scene
	_marble = scene.get_node("Marble") as Marble
	if not _marble.control_enabled:
		return
	_start_pos = _marble.global_position
	_attempt_time = 0.0
	_phase = "drive"
	print("[SMOKE] attempt=%d start pos=(%.2f, %.2f, %.2f) control_enabled=true" % [
		_attempt, _start_pos.x, _start_pos.y, _start_pos.z])


func _drive(delta: float) -> void:
	_sim_time += delta
	_attempt_time += delta
	var pos := _marble.global_position
	var flat_dist := Vector2(pos.x - _start_pos.x, pos.z - _start_pos.z).length()
	_max_dist = maxf(_max_dist, flat_dist)
	_gems_max = maxi(_gems_max, int(_game.get("_gems_collected")))

	if bool(_game.get("_finished")):
		if not _finished_once:
			_finished_once = true
			_finish_time = float(_game.get("_time"))
			_finish_gems = int(_game.get("_gems_collected"))
			var total_gems: int = _game.get("_builder").gems.size()
			print("[SMOKE] FINISH reached attempt=%d time=%.2fs gems=%d/%d pos=(%.2f, %.2f, %.2f)" % [
				_attempt, _finish_time, _finish_gems, total_gems,
				pos.x, pos.y, pos.z])
		_release_all()
		if _sim_time >= MIN_SIM_SECONDS and _wall_seconds() >= MIN_WALL_SECONDS:
			_finish(true, "finished + duration met")
		else:
			_phase = "hold"
			_restart_hold = 2.0
		return

	if _attempt_time > ATTEMPT_TIMEOUT:
		print("[SMOKE] attempt=%d TIMEOUT pos=(%.2f, %.2f, %.2f) dist=%.2fm gems=%d waypoint=%d/%d" % [
			_attempt, pos.x, pos.y, pos.z, flat_dist,
			int(_game.get("_gems_collected")), _waypoint, ROUTE.size()])
		_release_all()
		if _sim_time >= MIN_SIM_SECONDS and _wall_seconds() >= MIN_WALL_SECONDS:
			_finish(_finished_once or _gems_max > 0, "attempt timeout, duration met")
		else:
			_phase = "hold"
			_restart_hold = 0.5
		return

	_steer(pos)


## Waypoint bot: converts the desired world direction into camera-relative
## action strengths, exactly like TouchControls._apply_stick does.
func _steer(pos: Vector3) -> void:
	var wp := ROUTE[_waypoint]
	var to_wp := Vector3(wp.x - pos.x, 0.0, wp.y - pos.z)
	if to_wp.length() < WAYPOINT_RADIUS:
		_waypoint = mini(_waypoint + 1, ROUTE.size() - 1)
		wp = ROUTE[_waypoint]
		to_wp = Vector3(wp.x - pos.x, 0.0, wp.y - pos.z)
	if to_wp.length_squared() < 0.0001:
		_release_all()
		return
	var world_dir := to_wp.normalized()
	var local := Basis(Vector3.UP, -_marble.steer_yaw) * world_dir
	var strengths := [maxf(0.0, -local.x), maxf(0.0, local.x),
		maxf(0.0, -local.z), maxf(0.0, local.z)]
	for i in MOVE_ACTIONS.size():
		if strengths[i] > 0.05:
			Input.action_press(MOVE_ACTIONS[i], strengths[i])
		else:
			Input.action_release(MOVE_ACTIONS[i])


func _release_all() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _finish(ok: bool, reason: String) -> void:
	if _phase == "done":
		return
	_phase = "done"
	_release_all()
	var movement_ok := _max_dist > 5.0
	var progress_ok := _finished_once or _gems_max > 0
	var pass_all := ok and movement_ok and progress_ok
	print("[SMOKE] summary attempts=%d sim_time=%.1fs wall_time=%.1fs max_dist=%.2fm gems_max=%d finished=%s finish_time=%.2fs reason=%s" % [
		_attempt, _sim_time, _wall_seconds(), _max_dist, _gems_max,
		str(_finished_once), _finish_time, reason])
	print("[SMOKE] asserts movement(>5m)=%s progress(gem_or_finish)=%s duration(>=60s)=%s" % [
		str(movement_ok), str(progress_ok),
		str(_sim_time >= 60.0 and _wall_seconds() >= 60.0)])
	print("[SMOKE] RESULT=%s" % ("PASS" if pass_all else "FAIL"))
	get_tree().quit(0 if pass_all else 1)
