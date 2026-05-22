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
		"mass": 24.0,
		"engine_momentum_output": 100.0,
		"thruster_allocated_momentum": 32.0,
		"runtime_topology_segments": [
			{"node_index": 1, "joint_drive_kind": "rotary", "allocated_limb_momentum": 24.0, "momentum_min": 1.0, "momentum_max": 80.0, "mass": 6.0, "a_local": Vector2.ZERO, "b_local": Vector2(1.0, 0.0)},
			{"node_index": 2, "joint_drive_kind": "rotary", "allocated_limb_momentum": 14.0, "momentum_min": 1.0, "momentum_max": 80.0, "mass": 4.0, "a_local": Vector2(1.0, 0.0), "b_local": Vector2(2.0, 0.0)},
		],
		"runtime_module_bindings": [
			{"target_nodes": [1, 2], "allocated_limb_momentum_by_node": {"1": 24.0, "2": 14.0}},
		],
	}
	main._apply_engine_momentum_budget(stats, "hero")
	if abs(float(stats.get("bound_limb_allocated_momentum", 0.0)) - 38.0) > 0.001:
		_fail("Bound limb allocation mismatch")
	if abs(float(stats.get("engine_momentum_required", 0.0)) - 70.0) > 0.001:
		_fail("Total allocated momentum mismatch")
	if float(stats.get("engine_momentum_margin", 0.0)) < 29.999:
		_fail("Engine margin should remain positive")
	stats["thruster_allocated_momentum"] = 80.0
	main._apply_engine_momentum_budget(stats, "hero")
	if float(stats.get("engine_momentum_margin", 0.0)) >= 0.0:
		_fail("Over allocation should be invalid/negative")
	print("POWER_CHAIN_BUDGET_V3_PROBE ok")
	quit()
