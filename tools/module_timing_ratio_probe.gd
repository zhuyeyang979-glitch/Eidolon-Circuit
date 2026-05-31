extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var fighter := FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.active = true
	fighter.health = 100
	fighter.stats = {
		"teamedit_runtime_topology": true,
		"engine_motion_scale": 1.0,
		"runtime_topology_segments": [
			{"node_index": 1, "part_kind": "limb_muscle", "a_local": Vector2.ZERO, "b_local": Vector2(0.7, 0.0), "mass": 5.0, "joint_output_momentum_base": 140.0},
			{"node_index": 2, "part_kind": "terminal", "a_local": Vector2(0.7, 0.0), "b_local": Vector2(1.05, 0.0), "mass": 3.0, "joint_output_momentum_base": 120.0},
		],
	}
	var binding := {
		"attack_key": 1,
		"target_nodes": [1, 2],
		"module_action_profile": "two_link_forward_snap",
		"module_part": {
			"module_action_profile": "two_link_forward_snap",
			"startup_ratio": 1.0 / 3.0,
			"swing_arc_degrees": 180.0,
		},
	}
	var event := fighter.begin_runtime_module_action(Fighter.STATE_NORMAL, binding)
	if event.is_empty():
		_fail("Two-link runtime action did not start: %s" % String(fighter.get_meta("last_module_gate_reason", "")))
	var action: Dictionary = fighter.runtime_module_actions[0]
	var duration := float(action.get("duration", 0.0))
	var startup := float(action.get("startup_ratio", 0.0))
	var recovery := float(action.get("recovery_ratio", 0.0))
	if duration <= 0.0:
		_fail("Runtime action duration must be computed from motion budget.")
	if absf(startup - 1.0 / 3.0) > 0.001 or absf(recovery - 2.0 / 3.0) > 0.001:
		_fail("Module timing ratio changed: startup %.3f recovery %.3f" % [startup, recovery])
	print("MODULE_TIMING_RATIO_PROBE ok duration=%.3f startup=%.3f recovery=%.3f" % [duration, startup, recovery])
	quit()
