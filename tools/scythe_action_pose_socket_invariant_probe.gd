extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _segment_for_node(segments: Array, node_index: int) -> Dictionary:
	for raw_segment in segments:
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _parent_for_node(edges: Array, child_index: int) -> int:
	for raw_edge in edges:
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		var a := int(edge.get("a_node", edge.get("a", -1)))
		var b := int(edge.get("b_node", edge.get("b", -1)))
		var a_socket := String(edge.get("a_socket", ""))
		var b_socket := String(edge.get("b_socket", ""))
		if a == child_index and a_socket == "root_joint" and (b_socket == "distal" or b_socket.begins_with("torso_port:")):
			return b
		if b == child_index and b_socket == "root_joint" and (a_socket == "distal" or a_socket.begins_with("torso_port:")):
			return a
	return -1


func _assert_socket_gap(fighter, edges: Array, scythe_node: int, label: String) -> void:
	var segments: Array = fighter._runtime_topology_world_segments(true, true)
	var scythe := _segment_for_node(segments, scythe_node)
	if scythe.is_empty():
		_fail("%s missing scythe segment." % label)
		return
	var parent_index := _parent_for_node(edges, scythe_node)
	var parent := _segment_for_node(segments, parent_index)
	if parent.is_empty():
		_fail("%s missing parent segment." % label)
		return
	var actual: Vector2 = scythe.get("a", Vector2.ZERO)
	var expected: Vector2 = scythe.get("parent_socket_anchor", parent.get("b", actual))
	if String(parent.get("part_kind", "")) != "torso":
		expected = parent.get("b", expected)
	var gap := actual.distance_to(expected)
	if gap > 0.0005:
		_fail("%s scythe root detached during action: %.6f." % [label, gap])
		return
	if float(scythe.get("socket_gap", 0.0)) > 0.0005:
		_fail("%s resolver reported socket_gap %.6f." % [label, float(scythe.get("socket_gap", 0.0))])
		return


func _run_side(main: Node, side: String) -> void:
	var setup: Dictionary = Helpers.build_torso_limb_scythe_module(main, side)
	if setup.is_empty():
		_fail("Could not build scythe module test unit.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	var scythe := int(setup.get("scythe", -1))
	if not Helpers.bind_scythe_action_side(main, unit_bp, scythe, int(setup.get("module", -1)), side, 1):
		_fail("Could not bind scythe action side %s." % side)
		return
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var runtime: Array = Array(stats.get("runtime_module_bindings", []))
	if runtime.is_empty() or not (runtime[0] is Dictionary):
		_fail("Runtime binding missing for side %s." % side)
		return
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Scythe Socket Invariant", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var edges: Array = Array(stats.get("runtime_topology_edges", []))
	_assert_socket_gap(fighter, edges, scythe, "%s entry" % side)
	var event: Dictionary = fighter.begin_runtime_module_action("normal", Dictionary(runtime[0]), Vector2.RIGHT)
	if event.is_empty():
		_fail("Scythe action did not start for side %s: %s." % [side, String(fighter.get_meta("last_module_gate_reason", ""))])
		return
	for i in range(5):
		_assert_socket_gap(fighter, edges, scythe, "%s phase %d" % [side, i])
		fighter._tick_runtime_module_actions(0.08)
	_assert_socket_gap(fighter, edges, scythe, "%s recovery" % side)
	fighter.queue_free()


func _init() -> void:
	var main := Helpers.setup_main(self)
	_run_side(main, "left")
	_run_side(main, "right")
	print("SCYTHE_ACTION_POSE_SOCKET_INVARIANT_PROBE ok")
	quit(0)
