extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main: Node = Helpers.setup_main(self)
	var setup: Dictionary = Helpers.build_torso_limb(main)
	if setup.is_empty():
		_fail("Missing torso/limb setup for catalog-drop scythe link probe.")
	var unit_bp: Dictionary = setup["unit_bp"]
	var limb: int = int(setup["limb"])
	var scythe_part: int = Helpers.scythe_index(main)
	if scythe_part < 0:
		_fail("Scythe terminal missing.")
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	var edges: Array = topology.get("edges", [])
	var scythe_template: Dictionary = main._make_topology_node(unit_bp, nodes.size(), Vector2(0.5, 0.5), "muscle", scythe_part)
	var distal: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, edges, limb, "distal", -1)
	var parent_axis: Vector2 = main._topology_endpoint_axis_for_node(limb, nodes, edges)
	if parent_axis.length() <= 0.001:
		parent_axis = Vector2.RIGHT
	var root_extent: float = main._topology_node_visual_edge_extent_units("hero", scythe_template, unit_bp, "root_joint") / MainScene.TOPOLOGY_BOARD_PHYSICAL_UNITS
	var drop_topology_pos: Vector2 = distal + parent_axis.normalized() * root_extent
	var drop_local: Vector2 = main._topology_position_to_board_local(drop_topology_pos)
	main._drop_catalog_part_on_board("muscle", scythe_part, drop_local)
	unit_bp = main._editor_current_blueprint()
	topology = unit_bp.get("custom_topology", {})
	nodes = topology.get("nodes", [])
	edges = topology.get("edges", [])
	var scythe: int = nodes.size() - 1
	if scythe <= limb:
		_fail("Catalog drop did not append a scythe node.")
	var edge: Dictionary = Helpers.scythe_edge(main, unit_bp, scythe)
	if edge.is_empty():
		_fail("Catalog-dropped scythe did not auto-link near the limb distal socket.")
	var scythe_socket := String(main._topology_edge_socket_for_node(edge, scythe))
	var parent := int(main._topology_edge_other_node(edge, scythe))
	var parent_socket := String(main._topology_edge_socket_for_node(edge, parent))
	if scythe_socket != "root_joint":
		_fail("Catalog-dropped scythe linked with %s instead of root_joint." % scythe_socket)
	if parent != limb or parent_socket != "distal":
		_fail("Catalog-dropped scythe expected limb distal parent, got parent=%d socket=%s." % [parent, parent_socket])
	var gap: float = main._topology_max_socket_gap("hero", unit_bp, nodes, edges)
	if gap > 0.00001:
		_fail("Catalog-dropped scythe left socket gap %.6f." % gap)
	if int(main.editor_pending_orientation_node_index) != scythe:
		_fail("Catalog-dropped scythe did not start side orientation choice on the scythe node.")
	if not Helpers.orientation_buttons_visible(main):
		_fail("Catalog-dropped scythe did not show bottom LEFT/RIGHT orientation buttons.")
	if not Helpers.orientation_popup_visible(main):
		_fail("Catalog-dropped scythe did not show the side-mount popup.")
	var scythe_node: Dictionary = nodes[scythe]
	if String(scythe_node.get("visual_mount_side", "")) == "":
		_fail("Catalog-dropped scythe did not keep visual_mount_side.")
	if String(scythe_node.get("orientation_category", "")) != "orthogonal_side_mount":
		_fail("Catalog-dropped scythe lost orthogonal_side_mount category.")
	main.editor_orientation_popup_left_button.pressed.emit()
	unit_bp = main._editor_current_blueprint()
	nodes = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	scythe_node = nodes[scythe]
	if int(main.editor_pending_orientation_node_index) >= 0:
		_fail("Choosing popup LEFT did not close pending orientation state.")
	if String(scythe_node.get("visual_mount_side", "")) != "left":
		_fail("Choosing popup LEFT did not write visual_mount_side=left.")
	if bool(main.editor_orientation_popup_panel.visible):
		_fail("Choosing popup LEFT did not hide the side-mount popup.")
	print("SCYTHE_CATALOG_DROP_LINK_ORIENTATION_POPUP_PROBE ok scythe=%d parent=%d gap=%.6f side=%s" % [scythe, parent, gap, String(scythe_node.get("visual_mount_side", ""))])
	quit()
