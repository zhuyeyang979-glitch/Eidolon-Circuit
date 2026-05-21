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
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [0])
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "B", "limb_muscle", 0, Vector2.DOWN, [1])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	if edges.size() != 2:
		_fail("Expected two torso-port direct links, got %d." % edges.size())
	var duplicate_edges := edges.duplicate(true)
	duplicate_edges.append(main._topology_make_socket_edge(limb_a, "root_joint", torso, "torso_port:1"))
	var conflict: Dictionary = main._topology_endpoint_conflicts("hero", unit_bp, nodes, duplicate_edges)
	if not conflict.has("note"):
		_fail("Duplicate direct-muscle occupancy should be rejected.")
	if not main._unlink_topology_edge_at_index(unit_bp, 0):
		_fail("Direct edge unlink failed.")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	edges = topology.get("edges", [])
	if edges.size() != 1:
		_fail("Expected one edge after unlink, got %d." % edges.size())
	var relink_edges := edges.duplicate(true)
	relink_edges.append(main._topology_make_socket_edge(limb_a, "root_joint", torso, "torso_port:2"))
	conflict = main._topology_endpoint_conflicts("hero", unit_bp, nodes, relink_edges)
	if conflict.has("note"):
		_fail("After unlink, limb should be allowed to use a different empty torso port: %s" % String(conflict.get("note", "")))
	print("EDITOR_NO_FALSE_RESNAP_PROBE edges=%d" % edges.size())
	quit()
