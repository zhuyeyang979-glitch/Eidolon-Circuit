extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _fighter(output: float, mass: float) -> Fighter:
	var fighter := FighterScene.new()
	root.add_child(fighter)
	fighter.stats = {
		"teamedit_runtime_topology": true,
		"engine_motion_scale": 1.0,
		"runtime_topology_segments": [
			{"node_index": 1, "part_kind": "limb_muscle", "a_local": Vector2.ZERO, "b_local": Vector2(1.0, 0.0), "mass": mass, "joint_output_momentum_base": output},
		],
	}
	return fighter


func _duration(output: float, mass: float) -> float:
	var fighter := _fighter(output, mass)
	var result: Dictionary = fighter._runtime_action_motion_budget([1], {}, 180.0, 0.0, 0.8, Fighter.STATE_NORMAL)
	return float(result.get("duration", 0.0))


func _init() -> void:
	var weak := _duration(80.0, 8.0)
	var strong := _duration(240.0, 8.0)
	if not (strong < weak * 0.55):
		_fail("Stronger joint output should shorten module duration: weak=%.3f strong=%.3f" % [weak, strong])
	var light := _duration(160.0, 4.0)
	var heavy := _duration(160.0, 18.0)
	if not (heavy > light * 2.5):
		_fail("Heavier driven mass should lengthen module duration: light=%.3f heavy=%.3f" % [light, heavy])
	print("MODULE_DURATION_FROM_POWER_PROBE ok weak=%.3f strong=%.3f light=%.3f heavy=%.3f" % [weak, strong, light, heavy])
	quit()
