extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _fighter(stats: Dictionary):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "HEAT_TAG_TEST", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var laser_event := {
		"projectile": true,
		"gun_kind": "laser_gun",
		"ammo_kind": "laser",
		"projectile_style": "beam",
		"projectile_behavior": "laser",
		"module_action_profile": "laser_beam_activate",
	}
	var laser_reason := main._heat_reason_for_projectile_event(laser_event)
	if not laser_reason.contains("heat:projectile") or not laser_reason.contains("heat:laser"):
		_fail("Projectile heat reason should expose canonical projectile and laser tags.")
	var canonical = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.1, "laser_heat_relief": 0.25})
	canonical.add_heat(40.0, laser_reason)
	if absf(float(canonical.heat) - 30.0) > 0.01:
		_fail("Canonical heat tags should use the strongest matching relief.")
	var legacy = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "projectile_heat_relief": 0.1, "laser_heat_relief": 0.25})
	legacy.add_heat(40.0, "projectile laser gun")
	if absf(float(legacy.heat) - float(canonical.heat)) > 0.01:
		_fail("Legacy heat reason strings should remain compatible.")
	var repeat = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "repeat_heat_relief": 0.2})
	repeat.add_heat(50.0, "heat:repeat heat:gauntlet")
	if absf(float(repeat.heat) - 40.0) > 0.01:
		_fail("Repeat action canonical tags should apply repeat relief.")
	var dissipation = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "heat_dissipation": 40.0, "thermal_dissipation_rate": 40.0})
	dissipation.heat = 50.0
	dissipation.tick(1.0, 24.0)
	if float(dissipation.heat) >= 49.9:
		_fail("Runtime cooling should use thermal dissipation when cooling is zero.")
	var canonical_dissipation = _fighter({"heat_capacity": 100.0, "cooling": 0.0, "cooling_rate": 0.0, "runtime_cooling_rate": 40.0})
	canonical_dissipation.heat = 50.0
	canonical_dissipation.tick(1.0, 24.0)
	if float(canonical_dissipation.heat) >= 49.9:
		_fail("Runtime cooling should use canonical runtime_cooling_rate.")
	var stats := {"engine_idle_heat": 3.0, "booster_idle_heat": 2.0, "bound_limb_idle_heat": 1.0, "thermal_load_pool": 20.0, "cooling_rate": 4.0, "runtime_cooling_rate": 9.0}
	main._apply_thermal_budget(stats, "hero")
	if absf(float(stats.get("thermal_load_pool", 0.0)) - 20.0) > 0.01 or absf(float(stats.get("cooling_pool", 0.0)) - 20.0) > 0.01:
		_fail("Thermal budget should write canonical pool and compatibility aliases.")
	if absf(float(stats.get("runtime_cooling_rate", 0.0)) - 9.0) > 0.01 or absf(float(stats.get("thermal_dissipation_rate", 0.0)) - 9.0) > 0.01:
		_fail("Thermal budget should preserve canonical runtime cooling aliases.")
	if failed:
		quit(1)
		return
	print("HEAT_EVENT_TAG_UNIFICATION_PROBE ok canonical=%.1f legacy=%.1f repeat=%.1f dissipation=%.1f" % [float(canonical.heat), float(legacy.heat), float(repeat.heat), float(dissipation.heat)])
	quit()
