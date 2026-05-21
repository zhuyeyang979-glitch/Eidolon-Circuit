extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _base_stats(engine_output: float) -> Dictionary:
	return {
		"role": "hero",
		"engine_momentum_output": engine_output,
		"thruster_allocated_momentum": 45.0,
		"runtime_topology_segments": [
			{"node_index": 1, "part_kind": "limb_muscle", "mass": 5.0, "a_local": Vector2.ZERO, "b_local": Vector2(0.5, 0.0), "joint_drive_kind": "rotation", "momentum_min": 10.0, "momentum_max": 80.0, "allocated_limb_momentum": 35.0},
		],
		"runtime_module_bindings": [
			{"runtime_valid": true, "target_nodes": [1], "module_part": {}},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ok := _base_stats(90.0)
	main._apply_engine_momentum_budget(ok, "hero")
	if absf(float(ok.get("engine_momentum_required", 0.0)) - 80.0) > 0.01:
		_fail("Required allocation should be thruster + bound limb = 80.")
	if String(ok.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Engine output 90 should cover allocation 80.")
	var bad := _base_stats(70.0)
	main._apply_engine_momentum_budget(bad, "hero")
	if not String(bad.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Engine output 70 should not cover allocation 80.")
	print("MOMENTUM_BUDGET_ALLOCATION_PROBE ok required=%.1f" % float(ok.get("engine_momentum_required", 0.0)))
	quit()
