extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var engine := {"engine_momentum_output": 120.0, "engine_heat_coeff": 0.06, "engine_family": "balanced", "mass": 8.0, "cost": 1, "slot_volume_tier": "M"}
	var stats := {"cooling": 90.0, "heat_capacity": 40.0, "cooling_heat_capacity": 90.0, "heat_dissipation": 90.0}
	main._merge_engine_stats(stats, engine)
	stats["booster_idle_heat"] = 5.0
	stats["bound_limb_idle_heat"] = 3.0
	stats["boost_heat"] = 99.0
	var expected_idle := float(stats.get("engine_idle_heat", 0.0)) + 5.0 + 3.0
	main._apply_thermal_budget(stats, "hero")
	if abs(float(stats.get("idle_heat_load", 0.0)) - expected_idle) > 0.001:
		_fail("Idle heat mismatch")
	if float(stats.get("thermal_margin", 0.0)) <= 0.0:
		_fail("Thermal margin should be positive")
	if String(stats.get("thermal_note", "")).find("Boost") >= 0:
		_fail("Boost heat must not participate in construction legality")
	var booster := {"thruster_family": "cruise_blue", "drive_demand": 20.0, "momentum_min": 20.0, "thruster_idle_heat_coeff": 0.02}
	var allocated_heat := main._booster_idle_heat_for_allocation(booster, 45.0)
	if absf(allocated_heat - 0.9) > 0.001:
		_fail("Thruster idle heat should be proportional to current drive allocation.")
	print("THERMAL_CHAIN_V3_PROBE ok")
	quit()
