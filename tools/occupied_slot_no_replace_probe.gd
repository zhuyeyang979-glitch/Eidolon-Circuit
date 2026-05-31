extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part := _first_torso(main)
	if torso_part < 0:
		_fail("No torso part found.")
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_part)
	var first := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "ROOT A", "limb_muscle", 0, Vector2.RIGHT, [0])
	if edges.size() != 1:
		_fail("First limb did not connect.")
	var used_socket := main._topology_canonical_socket_id(main._topology_edge_socket_for_node(edges[0], torso))
	var preserved_edge: Dictionary = Dictionary(edges[0]).duplicate(true)
	var second := nodes.size()
	nodes.append(main._topology_component_node(second, "ROOT B", main._topology_node_position(nodes[first]), "limb_muscle", 0, 1, [1]))
	var before_edges := edges.duplicate(true)
	var before_pos: Vector2 = main._topology_node_position(nodes[second])
	var result: Dictionary = main._topology_try_connect_sockets("hero", unit_bp, nodes, edges, second, "root_joint", torso, used_socket)
	if bool(result.get("ok", false)):
		_fail("Occupied torso slot accepted a replacement connection.")
	if edges.size() != before_edges.size():
		_fail("Rejected occupied-slot connection mutated edge count.")
	if Dictionary(edges[0]) != preserved_edge:
		_fail("Rejected occupied-slot connection replaced the original edge.")
	if main._topology_node_position(nodes[second]).distance_to(before_pos) > 0.00001:
		_fail("Rejected occupied-slot connection moved the new limb.")
	var conflict_edges := before_edges.duplicate(true)
	conflict_edges.append(main._topology_make_socket_edge(second, "root_joint", torso, used_socket))
	var conflicts := main._topology_endpoint_conflicts("hero", unit_bp, nodes, conflict_edges)
	if not conflicts.has("note"):
		_fail("Duplicate socket data was not reported as invalid.")
	print("OCCUPIED_SLOT_NO_REPLACE_PROBE ok socket=%s" % used_socket)
	quit()
