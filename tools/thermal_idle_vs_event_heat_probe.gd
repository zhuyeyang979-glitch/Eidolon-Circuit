extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "EVENT_HEAT", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var stats := {
		"role": "hero",
		"engine_idle_heat": 5.0,
		"booster_idle_heat": 3.0,
		"bound_limb_idle_heat": 2.0,
		"heat_capacity": 24.0,
		"cooling": 4.0,
		"boost_heat": 999.0,
		"normal_heat": 999.0,
		"active_heat": 999.0,
		"event_heat": 999.0,
	}
	main._apply_thermal_budget(stats, "hero")
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Runtime event heat should not make construction idle thermal legality fail.")
	if absf(float(stats.get("idle_heat_load", 0.0)) - 10.0) > 0.01:
		_fail("Idle heat should only include engine, thruster idle, and bound limb allocation.")
	var fighter = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "boost_heat_relief": 0.25})
	fighter.add_heat_event(40.0, ["boost"], "boost")
	if absf(float(fighter.heat) - 30.0) > 0.01:
		_fail("Event heat should still enter runtime heat meter through canonical tags.")
	if failed:
		quit(1)
		return
	print("THERMAL_IDLE_VS_EVENT_HEAT_PROBE ok idle=%.1f runtime=%.1f" % [float(stats.get("idle_heat_load", 0.0)), float(fighter.heat)])
	quit()
