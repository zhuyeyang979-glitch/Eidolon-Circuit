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


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index := _two_link_module(main)
	var torso_index := _first_torso(main)
	if module_index < 0 or torso_index < 0:
		_fail("Required torso or module missing.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	var pos_a: Vector2 = main._topology_position_to_board_local(main._topology_node_position(Dictionary(nodes[limb_a])))
	var pos_b: Vector2 = main._topology_position_to_board_local(main._topology_node_position(Dictionary(nodes[limb_b])))
	var group_point := pos_a.lerp(pos_b, 0.5)
	var candidate := main._pending_module_binding_candidate_for_point(unit_bp, group_point)
	if candidate.is_empty():
		_fail("Group halo click area did not resolve to a candidate.")
	var target_nodes: Array = Array(candidate.get("target_nodes", []))
	if not target_nodes.has(limb_a) or not target_nodes.has(limb_b):
		_fail("Group click candidate did not select the full two-link target group.")
	print("MODULE_BINDING_GROUP_CLICK_AREA_PROBE ok nodes=%s" % str(target_nodes))
	quit()
