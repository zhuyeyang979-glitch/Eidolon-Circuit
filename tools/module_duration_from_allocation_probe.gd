extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter_with(allocation: float, mass: float):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"unit_name": "ALLOC_PROBE",
		"owner_id": 1,
		"role": "hero",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 40.0,
			"runtime_topology_segments": [
				{"node_index": 1, "part_kind": "limb_muscle", "a_local": Vector2.ZERO, "b_local": Vector2(1.0, 0.0), "mass": mass, "allocated_limb_momentum": allocation, "joint_output_momentum_base": allocation},
			],
		},
	})
	return fighter


func _init() -> void:
	var fast = _fighter_with(80.0, 4.0)
	var slow = _fighter_with(40.0, 4.0)
	var heavy = _fighter_with(80.0, 12.0)
	var mod := {"startup_ratio": 1.0 / 3.0, "recovery_ratio": 2.0 / 3.0}
	var fast_budget: Dictionary = fast._runtime_action_motion_budget([1], mod, 180.0, 0.0, 1.0, "normal")
	var slow_budget: Dictionary = slow._runtime_action_motion_budget([1], mod, 180.0, 0.0, 1.0, "normal")
	var heavy_budget: Dictionary = heavy._runtime_action_motion_budget([1], mod, 180.0, 0.0, 1.0, "normal")
	if float(fast_budget.get("duration", 0.0)) >= float(slow_budget.get("duration", 0.0)):
		_fail("Higher allocated limb momentum should shorten action duration.")
	if float(heavy_budget.get("duration", 0.0)) <= float(fast_budget.get("duration", 0.0)):
		_fail("Heavier downstream mass should lengthen action duration.")
	print("MODULE_DURATION_FROM_ALLOCATION_PROBE ok fast=%.3f slow=%.3f heavy=%.3f" % [float(fast_budget.get("duration", 0.0)), float(slow_budget.get("duration", 0.0)), float(heavy_budget.get("duration", 0.0))])
	quit()
