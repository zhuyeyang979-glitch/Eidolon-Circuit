extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var stats := {
		"role": "hero",
		"engine_idle_heat": 6.0,
		"booster_idle_heat": 4.0,
		"bound_limb_idle_heat": 3.0,
		"cooling": 20.0,
		"heat_capacity": 40.0,
		"heat_dissipation": 4.0,
	}
	main._apply_thermal_budget(stats, "hero")
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Heat pool 40 should cover allocation idle heat.")
	if absf(float(stats.get("idle_heat_load", 0.0)) - 13.0) > 0.01:
		_fail("Idle heat should include engine + thruster + bound limb allocations.")
	if absf(float(stats.get("cooling", 0.0)) - 20.0) > 0.01:
		_fail("Cooling speed should remain unchanged by thermal load pool budgeting.")
	if absf(float(stats.get("thermal_margin", 0.0)) - 27.0) > 0.01:
		_fail("Thermal margin should use heat pool minus idle heat.")
	stats["cooling"] = 2.0
	stats["heat_capacity"] = 40.0
	main._apply_thermal_budget(stats, "hero")
	if String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Low cooling speed alone should not make the construction illegal when heat pool covers idle load.")
	stats["heat_capacity"] = 12.0
	stats["cooling_heat_capacity"] = 12.0
	main._apply_thermal_budget(stats, "hero")
	if not String(stats.get("thermal_note", "")).begins_with("INVALID"):
		_fail("Heat pool below allocation idle heat should be illegal.")
	var runtime_stats := {
		"role": "hero",
		"engine_momentum_output": 100.0,
		"thruster_drive_demand": 20.0,
		"thruster_boost_extra_demand": 10.0,
		"engine_idle_heat": 2.0,
		"booster_idle_heat": 1.5,
		"cooling": 12.0,
		"heat_capacity": 30.0,
		"runtime_topology_nodes": [{"slot": "limb_muscle", "part_index": 0}],
		"runtime_topology_segments": [{
			"node_index": 0,
			"part_kind": "limb_muscle",
			"joint_drive_kind": "standard",
			"joint_output_momentum_base": 40.0,
			"momentum_min": 10.0,
			"momentum_max": 80.0,
			"allocated_limb_momentum": 40.0,
			"limb_idle_heat_coeff": 0.025,
			"mass": 1.0,
			"a_local": Vector2.ZERO,
			"b_local": Vector2.RIGHT,
		}],
		"runtime_module_bindings": [{
			"runtime_valid": true,
			"target_nodes": [0],
			"joint_drive_allocation_by_node": {"0": 40.0},
			"module_part": {},
		}],
	}
	main._apply_engine_momentum_budget(runtime_stats, "hero")
	if absf(float(runtime_stats.get("bound_limb_idle_heat", 0.0)) - 1.0) > 0.001:
		_fail("Bound limb idle heat should come from current allocation * limb heat coeff.")
	main._apply_thermal_budget(runtime_stats, "hero")
	var runtime_expected := 2.0 + 1.5 + 1.0
	if absf(float(runtime_stats.get("idle_heat_load", 0.0)) - runtime_expected) > 0.001:
		_fail("Runtime idle heat should include engine + current thruster + current limb allocation heat.")
	print("THERMAL_ALLOCATION_PROBE ok")
	quit()
