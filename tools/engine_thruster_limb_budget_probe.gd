extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _base_stats(engine_output: float, thruster_allocation: float, limb_allocation: float) -> Dictionary:
	return {
		"role": "hero",
		"engine_momentum_output": engine_output,
		"thruster_allocated_momentum": thruster_allocation,
		"runtime_topology_segments": [
			{"node_index": 4, "part_kind": "limb_muscle", "mass": 4.0, "a_local": Vector2.ZERO, "b_local": Vector2(0.5, 0.0), "joint_drive_kind": "rotation", "momentum_min": 6.0, "momentum_max": 80.0, "allocated_limb_momentum": limb_allocation},
		],
		"runtime_module_bindings": [
			{"runtime_valid": true, "target_nodes": [4], "module_part": {}},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ok := _base_stats(100.0, 42.0, 38.0)
	main._apply_engine_momentum_budget(ok, "hero")
	if String(ok.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Engine output 100 should cover thruster 42 + limb 38.")
	if absf(float(ok.get("engine_momentum_required", 0.0)) - 80.0) > 0.01:
		_fail("Required engine power should equal thruster + bound limb allocation.")
	var bad := _base_stats(70.0, 42.0, 38.0)
	main._apply_engine_momentum_budget(bad, "hero")
	if not String(bad.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Engine output 70 should fail against allocation 80.")
	print("ENGINE_THRUSTER_LIMB_BUDGET_PROBE ok required=%.1f" % float(ok.get("engine_momentum_required", 0.0)))
	quit()
