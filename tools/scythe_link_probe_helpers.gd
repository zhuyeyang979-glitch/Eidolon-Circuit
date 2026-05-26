extends RefCounted

const MainScene := preload("res://scripts/main.gd")


static func first_torso(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


static func first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


static func scythe_index(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


static func setup_main(tree: SceneTree) -> Node:
	var main = MainScene.new()
	tree.root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main._start_blank_topology()
	return main


static func build_torso_limb(main: Node) -> Dictionary:
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = []
	var edges: Array = []
	var torso_part: int = first_torso(main)
	var limb_part: int = first_limb(main)
	if torso_part < 0 or limb_part < 0:
		return {}
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_part)
	var limb: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "HANDLE", "limb_muscle", limb_part, Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	return {"unit_bp": unit_bp, "nodes": nodes, "edges": edges, "torso": torso, "limb": limb}


static func append_loose_scythe_near_limb(main: Node, unit_bp: Dictionary, limb: int) -> int:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	var edges: Array = topology.get("edges", [])
	var index: int = nodes.size()
	var scythe_part: int = scythe_index(main)
	if scythe_part < 0:
		return -1
	var node: Dictionary = main._make_topology_node(unit_bp, index, Vector2(0.5, 0.5), "muscle", scythe_part)
	nodes.append(node)
	var distal: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb, "distal", index)
	var root_extent: float = main._topology_node_visual_edge_extent_units("hero", node, unit_bp, "root_joint") / MainScene.TOPOLOGY_BOARD_PHYSICAL_UNITS
	node["pos"] = distal + Vector2.RIGHT * root_extent
	nodes[index] = node
	topology["nodes"] = nodes
	unit_bp["custom_topology"] = topology
	main.editor_topology_node_index = index
	main.editor_selected_topology_nodes = [index]
	return index


static func scythe_edge(main: Node, unit_bp: Dictionary, scythe: int) -> Dictionary:
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	for raw_edge in Array(topology.get("edges", [])):
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		if main._topology_edge_has_node(edge, scythe):
			return edge
	return {}


static func orientation_buttons_visible(main: Node) -> bool:
	return main.editor_action_buttons.has("set_handedness_left") \
		and bool(main.editor_action_buttons["set_handedness_left"].visible) \
		and main.editor_action_buttons.has("set_handedness_right") \
		and bool(main.editor_action_buttons["set_handedness_right"].visible)


static func orientation_popup_visible(main: Node) -> bool:
	return main.editor_orientation_popup_panel != null \
		and bool(main.editor_orientation_popup_panel.visible) \
		and main.editor_orientation_popup_left_button != null \
		and bool(main.editor_orientation_popup_left_button.visible) \
		and main.editor_orientation_popup_right_button != null \
		and bool(main.editor_orientation_popup_right_button.visible)
