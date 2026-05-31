extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _stats(engine_budget: float) -> Dictionary:
	return {
		"role": "hero",
		"engine_momentum_output": engine_budget,
		"engine_momentum_budget": engine_budget,
		"thruster_allocated_momentum": 40.0,
		"runtime_topology_nodes": [
			{"slot": "muscle", "part_index": 0},
			{"slot": "limb_muscle", "part_index": 0},
			{"slot": "limb_muscle", "part_index": 1},
		],
		"runtime_topology_segments": [
			{"node_index": 1, "part_kind": "limb_muscle", "a_local": Vector2.ZERO, "b_local": Vector2(0.5, 0.0), "mass": 4.0, "joint_drive_kind": "rotation", "momentum_min": 20.0, "momentum_max": 80.0, "allocated_limb_momentum": 30.0, "joint_output_momentum_base": 120.0},
			{"node_index": 2, "part_kind": "limb_muscle", "a_local": Vector2.ZERO, "b_local": Vector2(0.5, 0.0), "mass": 4.0, "joint_drive_kind": "rotation", "momentum_min": 20.0, "momentum_max": 80.0, "allocated_limb_momentum": 999.0, "joint_output_momentum_base": 120.0},
		],
		"runtime_module_bindings": [
			{"runtime_valid": true, "target_nodes": [1], "module_part": {}},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ok := _stats(100.0)
	main._apply_engine_momentum_budget(ok, "hero")
	if absf(float(ok.get("engine_momentum_required", 0.0)) - 70.0) > 0.01:
		_fail("Budget should count thruster allocation plus only bound limb allocation: %.2f" % float(ok.get("engine_momentum_required", 0.0)))
	if int(ok.get("bound_joint_count", 0)) != 1:
		_fail("Only one bound limb should be counted.")
	if String(ok.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Sufficient budget should be legal: %s" % String(ok.get("engine_momentum_note", "")))
	var bad := _stats(60.0)
	main._apply_engine_momentum_budget(bad, "hero")
	if not String(bad.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Insufficient engine momentum budget should be invalid.")
	print("JOINT_ENGINE_BUDGET_PROBE ok allocation=%.1f margin=%.1f" % [float(ok.get("engine_momentum_required", 0.0)), float(ok.get("engine_momentum_margin", 0.0))])
	quit()
