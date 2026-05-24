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


func _setup_unit(main) -> Dictionary:
	var module_index := _two_link_module(main)
	var torso_index := _first_torso(main)
	if module_index < 0 or torso_index < 0:
		_fail("Required torso or Two-Link module missing.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._start_editor_module_binding_flow(0, main._selected_component("hero", "module", module_index))
	main._refresh_editor_visual_views()
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	_setup_unit(main)
	var board = main.assembly_board_view
	if board == null:
		_fail("Assembly board missing.")
	if board.retained_binding_group_items.is_empty():
		_fail("Binding flow did not create retained group halo items.")
	var found_group := false
	for raw_item in board.retained_binding_group_items.values():
		if raw_item == null:
			continue
		var payload: Dictionary = raw_item.payload
		if Array(payload.get("nodes", [])).size() >= 2 and String(payload.get("state", "")) == "binding_valid":
			found_group = true
			break
	if not found_group:
		_fail("No valid multi-node binding halo payload was retained.")
	print("MODULE_BINDING_GROUP_HALO_VISUAL_PROBE ok groups=%d" % board.retained_binding_group_items.size())
	quit()
