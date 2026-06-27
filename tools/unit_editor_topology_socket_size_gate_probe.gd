extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _part_size_rank(main, slot_key: String, part_index: int) -> int:
	var part: Dictionary = main._selected_component("hero", slot_key, part_index)
	return int(main._size_tier_rank(main._part_size_tier_label(part, slot_key)))


func _node_size_rank(main, unit_bp: Dictionary, node: Dictionary) -> int:
	var slot_key := String(node.get("slot", node.get("slot_key", "")))
	var part: Dictionary = main._topology_node_part("hero", node, unit_bp)
	return int(main._size_tier_rank(main._part_size_tier_label(part, slot_key)))


func _oversized_part_index(main, slot_key: String, socket_capacity: int, current_index: int) -> int:
	for i in range(main._catalog_for("hero", slot_key).size()):
		if i == current_index:
			continue
		if _part_size_rank(main, slot_key, i) > socket_capacity:
			return i
	return -1


func _root_socket_connection(main, unit_bp: Dictionary) -> Dictionary:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	var edges: Array = Array(topology.get("edges", []))
	for raw_edge in edges:
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		var a: int = int(main._topology_edge_node_a(edge))
		var b: int = int(main._topology_edge_node_b(edge))
		if a < 0 or b < 0 or a >= nodes.size() or b >= nodes.size():
			continue
		var a_socket: String = String(main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, a)))
		var b_socket: String = String(main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edge, b)))
		if a_socket == "root_joint" and b_socket != "root_joint":
			return {"child": a, "host": b, "child_socket": a_socket, "host_socket": b_socket}
		if b_socket == "root_joint" and a_socket != "root_joint":
			return {"child": b, "host": a, "child_socket": b_socket, "host_socket": a_socket}
	return {}


func _oversized_topology_mutation(main, unit_bp: Dictionary) -> Dictionary:
	var topology: Dictionary = Dictionary(unit_bp.get("custom_topology", {})).duplicate(true)
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	var connection := _root_socket_connection(main, unit_bp)
	if connection.is_empty():
		return {}
	var child_index := int(connection.get("child", -1))
	var host_index := int(connection.get("host", -1))
	if child_index < 0 or host_index < 0 or child_index >= nodes.size() or host_index >= nodes.size():
		return {}
	if not (nodes[child_index] is Dictionary) or not (nodes[host_index] is Dictionary):
		return {}
	var child_node: Dictionary = Dictionary(nodes[child_index]).duplicate(true)
	var host_node: Dictionary = Dictionary(nodes[host_index])
	var child_slot := String(child_node.get("slot", child_node.get("slot_key", "")))
	var host_capacity := _node_size_rank(main, unit_bp, host_node)
	var replacement := _oversized_part_index(main, child_slot, host_capacity, int(child_node.get("part_index", -1)))
	if replacement < 0:
		return {}
	var replacement_part: Dictionary = main._selected_component("hero", child_slot, replacement)
	child_node["part_index"] = replacement
	child_node["part_name"] = String(replacement_part.get("name", ""))
	nodes[child_index] = child_node
	topology["nodes"] = nodes
	return {
		"topology": topology,
		"child_index": child_index,
		"host_index": host_index,
		"host_capacity": host_capacity,
		"replacement_size": _part_size_rank(main, child_slot, replacement),
		"connection": connection,
	}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var legal_bp := LegalStarterBlueprintFixture.build(main, "Topology Socket Size Gate Legal")
	_require(not legal_bp.is_empty(), "Could not build legal starter fixture.")
	if failed:
		quit(1)
		return
	var legal_report: Dictionary = main._unit_editor_legality_report("hero", legal_bp)
	_require(bool(legal_report.get("valid", false)), "Legal starter should remain valid before socket-size mutation: %s" % str(legal_report))

	var mutation := _oversized_topology_mutation(main, legal_bp)
	_require(not mutation.is_empty(), "Need a live topology child part larger than its host socket capacity.")
	if failed:
		quit(1)
		return
	var oversized_bp: Dictionary = legal_bp.duplicate(true)
	oversized_bp["custom_topology"] = mutation.get("topology", {})

	var oversized_report: Dictionary = main._unit_editor_legality_report("hero", oversized_bp)
	_require(not bool(oversized_report.get("valid", true)), "Oversized live topology socket should be rejected: %s" % str(oversized_report))
	_require(_has_code(oversized_report, "socket_part_too_large"), "Oversized live topology socket should report socket_part_too_large: %s; mutation=%s" % [str(oversized_report), str(mutation)])

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_TOPOLOGY_SOCKET_SIZE_GATE_PROBE ok")
	quit(0)
