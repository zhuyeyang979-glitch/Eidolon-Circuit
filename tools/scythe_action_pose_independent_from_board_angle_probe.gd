extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _axis_for_node(stats: Dictionary, node_index: int) -> Vector2:
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -999)) == node_index:
			return Vector2(Dictionary(raw_segment).get("axis_local", Vector2.ZERO)).normalized()
	return Vector2.ZERO


func _init() -> void:
	var main := Helpers.setup_main(self)
	var setup: Dictionary = Helpers.build_torso_limb_scythe_module(main, "right")
	if setup.is_empty():
		_fail("Could not build scythe module test unit.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var scythe: int = int(setup.get("scythe", -1))
	if not Helpers.bind_scythe_action_side(main, unit_bp, scythe, int(setup.get("module", -1)), "left", 1):
		_fail("Could not bind left scythe action side.")
		return
	var baseline_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var baseline_axis := _axis_for_node(baseline_stats, scythe)
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	var node: Dictionary = Dictionary(nodes[scythe]).duplicate(true)
	node["local_angle"] = deg_to_rad(37.0)
	nodes[scythe] = node
	topology["nodes"] = nodes
	unit_bp["custom_topology"] = topology
	var changed_stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var changed_axis := _axis_for_node(changed_stats, scythe)
	if baseline_axis.length() < 0.9 or changed_axis.length() < 0.9:
		_fail("Missing runtime axes after board angle change.")
		return
	if baseline_axis.dot(changed_axis) < 0.995:
		_fail("Scythe action pose changed when board local_angle changed: %s -> %s." % [str(baseline_axis), str(changed_axis)])
		return
	print("SCYTHE_ACTION_POSE_INDEPENDENT_FROM_BOARD_ANGLE_PROBE ok axis=%s" % str(changed_axis))
	quit(0)
