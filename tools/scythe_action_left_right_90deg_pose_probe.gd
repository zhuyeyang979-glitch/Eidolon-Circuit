extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _segment_axis_for_node(stats: Dictionary, node_index: int) -> Vector2:
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		if int(segment.get("node_index", -999)) == node_index:
			return Vector2(segment.get("axis_local", Vector2.ZERO)).normalized()
	return Vector2.ZERO


func _axes_for_side(main: Node, side: String) -> Dictionary:
	var setup: Dictionary = Helpers.build_torso_limb_scythe_module(main, "right")
	if setup.is_empty():
		_fail("Could not build scythe module test unit.")
		return {}
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var scythe: int = int(setup.get("scythe", -1))
	var limb: int = int(setup.get("limb", -1))
	if not Helpers.bind_scythe_action_side(main, unit_bp, scythe, int(setup.get("module", -1)), side, 1):
		_fail("Could not bind scythe action side %s." % side)
		return {}
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	return {
		"scythe": _segment_axis_for_node(stats, scythe),
		"parent": _segment_axis_for_node(stats, limb),
	}


func _init() -> void:
	var main := Helpers.setup_main(self)
	var left_axes: Dictionary = _axes_for_side(main, "left")
	var right_axes: Dictionary = _axes_for_side(main, "right")
	var left_axis: Vector2 = left_axes.get("scythe", Vector2.ZERO)
	var left_parent: Vector2 = left_axes.get("parent", Vector2.RIGHT)
	var right_axis: Vector2 = right_axes.get("scythe", Vector2.ZERO)
	var right_parent: Vector2 = right_axes.get("parent", Vector2.RIGHT)
	if left_axis.length() < 0.9 or right_axis.length() < 0.9:
		_fail("Missing scythe runtime axes.")
		return
	if left_parent.length() < 0.9 or right_parent.length() < 0.9 or left_parent.dot(right_parent) < 0.99:
		_fail("Side-mount action side should not rotate the parent limb: left=%s right=%s." % [str(left_parent), str(right_parent)])
		return
	var expected_left := left_parent.normalized().rotated(-PI * 0.5)
	var expected_right := right_parent.normalized().rotated(PI * 0.5)
	if left_axis.dot(expected_left) < 0.99:
		_fail("Left action side should be parent axis -90deg, got %s expected %s." % [str(left_axis), str(expected_left)])
		return
	if right_axis.dot(expected_right) < 0.99:
		_fail("Right action side should be parent axis +90deg, got %s expected %s." % [str(right_axis), str(expected_right)])
		return
	if left_axis.dot(right_axis) > -0.96:
		_fail("Left/right action default poses should differ by 180deg.")
		return
	print("SCYTHE_ACTION_LEFT_RIGHT_90DEG_POSE_PROBE ok left=%s right=%s" % [str(left_axis), str(right_axis)])
	quit(0)
