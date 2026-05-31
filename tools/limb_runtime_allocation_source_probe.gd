extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MotionBudgetScene := preload("res://scripts/motion_budget.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "LIMB_ALLOC_SOURCE_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 40.0,
			"runtime_topology_segments": [
				{
					"node_index": 1,
					"part_kind": "limb_muscle",
					"a_local": Vector2.ZERO,
					"b_local": Vector2(1.0, 0.0),
					"mass": 8.0,
					"allocated_limb_momentum": 20.0,
					"joint_output_momentum_base": 220.0,
					"momentum_min": 0.0,
					"momentum_max": 240.0,
				},
			],
			"runtime_topology_edges": [],
		},
	})
	var module_part := {"startup_ratio": 1.0 / 3.0, "recovery_ratio": 2.0 / 3.0}
	var binding := {"target_nodes": [1], "allocated_limb_momentum_by_node": {"1": 20.0}}
	var budget: Dictionary = fighter._runtime_action_motion_budget([1], module_part, 180.0, 0.0, 1.0, "normal", binding)
	var duration := float(budget.get("duration", 0.0))
	var expected: Dictionary = MotionBudgetScene.estimate_motion_budget({"mass": 8.0, "length": 1.0, "output": 20.0}, module_part, 180.0, 0.0, 1.0, "normal")
	var expected_duration := float(expected.get("duration", 0.0))
	if absf(duration - expected_duration) > 0.02:
		_fail("Runtime motion should use allocated limb momentum %.3f, got %.3f." % [expected_duration, duration])
	if duration <= 0.5:
		_fail("Runtime motion still appears to be using hidden base output; duration=%.3f" % duration)
	print("LIMB_RUNTIME_ALLOCATION_SOURCE_PROBE ok duration=%.3f expected=%.3f" % [duration, expected_duration])
	quit()
