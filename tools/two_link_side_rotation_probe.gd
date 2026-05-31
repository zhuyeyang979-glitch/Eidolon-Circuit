extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _angle_delta(now_angle: float, base_angle: float) -> float:
	return wrapf(now_angle - base_angle, -PI, PI)


func _first_angle_for(fighter, action: Dictionary) -> float:
	var overrides: Dictionary = fighter._runtime_two_link_forward_snap_local_overrides(action)
	if overrides.is_empty():
		_fail("Two-Link override was empty.")
	for key in overrides.keys():
		var segment: Dictionary = Dictionary(overrides[key])
		if int(segment.get("node_index", -1)) == 10:
			var a: Vector2 = fighter._runtime_local_vector(segment.get("a_local", Vector2.ZERO))
			var b: Vector2 = fighter._runtime_local_vector(segment.get("b_local", Vector2.RIGHT))
			return (b - a).angle()
	_fail("First segment override missing.")
	return 0.0


func _make_fighter(first_a: Vector2, first_b: Vector2, second_b: Vector2):
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.stats = {
		"teamedit_runtime_topology": true,
		"runtime_topology_segments": [
			{"node_index": 10, "part_kind": "limb_muscle", "a_local": first_a, "b_local": first_b, "axis_local": (first_b - first_a).normalized()},
			{"node_index": 11, "part_kind": "limb_muscle", "a_local": first_b, "b_local": second_b, "axis_local": (second_b - first_b).normalized()},
		],
	}
	return fighter


func _init() -> void:
	var duration := 1.2
	var startup_ratio := 1.0 / 3.0
	var left = _make_fighter(Vector2(0.0, -1.0), Vector2(0.0, -1.4), Vector2(0.0, -1.8))
	var right = _make_fighter(Vector2(0.0, 1.0), Vector2(0.0, 1.4), Vector2(0.0, 1.8))
	var left_base := -PI * 0.5
	var right_base := PI * 0.5
	var startup_action := {"target_nodes": [10, 11], "duration": duration, "timer": duration * (1.0 - startup_ratio * 0.5), "startup_ratio": startup_ratio}
	var left_start_delta := _angle_delta(_first_angle_for(left, startup_action), left_base)
	var right_start_delta := _angle_delta(_first_angle_for(right, startup_action), right_base)
	if left_start_delta <= 0.0:
		_fail("Left-side limb should strike clockwise during startup, delta=%.3f." % left_start_delta)
	if right_start_delta >= 0.0:
		_fail("Right-side limb should strike counterclockwise during startup, delta=%.3f." % right_start_delta)
	var recovery_action := {"target_nodes": [10, 11], "duration": duration, "timer": duration * 0.25, "startup_ratio": startup_ratio}
	var left_recovery_delta := _angle_delta(_first_angle_for(left, recovery_action), 0.0)
	var right_recovery_delta := _angle_delta(_first_angle_for(right, recovery_action), 0.0)
	if left_recovery_delta >= 0.0:
		_fail("Left-side limb should recover counterclockwise, delta=%.3f." % left_recovery_delta)
	if right_recovery_delta <= 0.0:
		_fail("Right-side limb should recover clockwise, delta=%.3f." % right_recovery_delta)
	print("TWO_LINK_SIDE_ROTATION_PROBE left_start=%.3f right_start=%.3f left_recover=%.3f right_recover=%.3f" % [left_start_delta, right_start_delta, left_recovery_delta, right_recovery_delta])
	quit()
