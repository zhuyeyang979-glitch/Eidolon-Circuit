extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _assert_contains(label: String, text: String, phrase: String) -> void:
	if text.find(phrase) < 0:
		_fail("%s missing phrase: %s" % [label, phrase])


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "ACTIVE_COOL_PROBE", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var readme := FileAccess.get_file_as_string("res://README.md")
	_assert_contains("README", readme, "active cooling window")
	_assert_contains("README", readme, "散热窗口")
	_assert_contains("README", readme, "post-battle review log")

	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	for token in [
		"begin_cooling_exposure",
		"cooling_exposed_timer",
		"cooling_exposed_damage_mult",
		"_refresh_cooling_smoke",
	]:
		_assert_contains("fighter.gd", fighter_source, token)

	var manual = _fighter({"heat_capacity": 100.0, "cooling": 10.0, "manual_cooling": 20.0})
	manual.heat = 80.0
	manual.manual_cool(1.0)
	if absf(float(manual.heat) - 70.0) > 0.01:
		_fail("Manual cooling should immediately vent heat, got %.2f." % float(manual.heat))
	if float(manual.cooling_exposed_timer) < 0.39 or String(manual.get_meta("cooling_exposed_kind", "")) != "manual":
		_fail("Manual cooling should mark a readable exposure window.")
	if manual.smoke_cloud == null or not bool(manual.smoke_cloud.visible) or manual.smoke_cloud.polygon.size() <= 0:
		_fail("Manual cooling should render a visible vent cloud.")

	var normal_hit = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "health": 100})
	normal_hit.take_hit(10, "normal", 2, "blunt", "weapon")
	if int(normal_hit.health) != 90:
		_fail("Baseline hit should deal 10 damage, got health=%d." % int(normal_hit.health))
	var exposed_hit = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "health": 100})
	exposed_hit.begin_cooling_exposure(0.5, "active")
	exposed_hit.take_hit(10, "normal", 2, "blunt", "weapon")
	if int(exposed_hit.health) != 89:
		_fail("Cooling exposure should add a small punish bonus, got health=%d." % int(exposed_hit.health))
	exposed_hit.tick(0.6, 24.0)
	exposed_hit.take_hit(10, "normal", 2, "blunt", "weapon")
	if int(exposed_hit.health) != 79:
		_fail("Cooling exposure damage bonus should expire after the window, got health=%d." % int(exposed_hit.health))

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.match_time_remaining = MainScene.MATCH_TARGET_SECONDS - 9.0
	main.battle_message = ""
	var active = _fighter({
		"heat_capacity": 100.0,
		"cooling": 0.0,
		"cool_burst": 46.0,
		"cool_lock": 0.44,
		"command": "214214",
	})
	active.heat = 90.0
	main._try_active_cooling_module(active, 1)
	if float(active.heat) > 44.01:
		_fail("Active cooling module should vent its burst amount, got %.2f." % float(active.heat))
	if absf(float(active.get_meta("active_cool_lock", 0.0)) - 0.44) > 0.01:
		_fail("Active cooling module should lock movement for its authored duration.")
	if String(active.get_meta("cooling_exposed_kind", "")) != "active" or float(active.get_meta("cooling_exposed_timer", 0.0)) < 0.43:
		_fail("Active cooling should mark an active exposure window.")
	var summary := main._battle_command_log_summary_text(4)
	_assert_contains("command summary", summary, "散热")
	_assert_contains("command summary", summary, "冷却")
	_assert_contains("command summary", summary, "主动散热")

	print("ACTIVE_COOLING_MINDGAME_PROBE failed=%s manual=%.1f active=%.1f" % [str(failed), float(manual.heat), float(active.heat)])
	quit(1 if failed else 0)
