extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _stats_with_allocation(allocation: float) -> Dictionary:
	return {
		"role": "hero",
		"engine_momentum_output": 120.0,
		"thruster_allocated_momentum": 20.0,
		"runtime_topology_segments": [
			{"node_index": 1, "part_kind": "limb_muscle", "mass": 4.0, "a_local": Vector2.ZERO, "b_local": Vector2(0.5, 0.0), "joint_drive_kind": "rotation", "momentum_min": 30.0, "momentum_max": 70.0, "allocated_limb_momentum": allocation},
		],
		"runtime_module_bindings": [
			{"runtime_valid": true, "target_nodes": [1], "module_part": {}},
		],
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var ok := _stats_with_allocation(50.0)
	main._apply_engine_momentum_budget(ok, "hero")
	if String(ok.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Allocation inside limb momentum range should be legal: %s" % String(ok.get("engine_momentum_note", "")))
	var low := _stats_with_allocation(10.0)
	main._apply_engine_momentum_budget(low, "hero")
	if not String(low.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Allocation below limb momentum_min should be illegal.")
	var high := _stats_with_allocation(90.0)
	main._apply_engine_momentum_budget(high, "hero")
	if not String(high.get("engine_momentum_note", "")).begins_with("INVALID"):
		_fail("Allocation above limb momentum_max should be illegal.")
	print("LIMB_MOMENTUM_RANGE_PROBE ok")
	quit()
