extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter := FighterScene.new()
	root.add_child(fighter)
	fighter.stats = {
		"teamedit_runtime_topology": true,
		"engine_motion_scale": 1.0,
		"runtime_topology_segments": [
			{"node_index": 1, "part_kind": "terminal", "a_local": Vector2.ZERO, "b_local": Vector2(1.0, 0.0), "mass": 8.0, "joint_drive_kind": "hybrid", "joint_output_momentum_base": 80.0},
		],
	}
	var result: Dictionary = fighter._runtime_action_motion_budget([1], {"module_extension_m": 2.0}, 90.0, 2.0, 0.8, Fighter.STATE_NORMAL)
	var angular_time := float(result.get("angular_time", 0.0))
	var extension_time := float(result.get("extension_time", 0.0))
	var duration := float(result.get("duration", 0.0))
	if duration <= 0.0:
		_fail("Hybrid motion did not produce a duration.")
	if absf(duration - maxf(angular_time, extension_time)) > 0.001:
		_fail("Hybrid motion duration should be the slower of rotation/extension: duration %.3f angular %.3f extension %.3f" % [duration, angular_time, extension_time])
	print("HYBRID_JOINT_MOTION_PROBE ok duration=%.3f angular=%.3f extension=%.3f" % [duration, angular_time, extension_time])
	quit()
