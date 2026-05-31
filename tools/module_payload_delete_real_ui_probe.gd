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
	if module_index < 0:
		_fail("Two-Link module missing.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	var limb_node: Dictionary = Dictionary(nodes[limb_a]).duplicate(true)
	limb_node["modules"] = [module_index]
	limb_node["module"] = module_index
	limb_node["attack_key"] = 1
	nodes[limb_a] = limb_node
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "torso_node": torso}]
	unit_bp["module_bindings"] = [{"software_slot_index": 0, "module_index": module_index, "attack_key": 1, "target_kind": "limb", "target_nodes": [limb_a, limb_b], "target_torso_node": torso, "allocated_limb_momentum_by_node": {str(limb_a): 18.0, str(limb_b): 18.0}, "joint_drive_allocation_by_node": {str(limb_a): 18.0, str(limb_b): 18.0}}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main.editor_bound_module_tryout = {"attack_key": 1, "target_nodes": [limb_a, limb_b], "profile": "two_link_forward_snap"}
	main._refresh_torso_detail_view()
	var view = main.editor_torso_detail_view
	if view == null:
		_fail("Torso detail view missing.")
	var slot_index := -1
	for i in range(view.software_entries.size()):
		if view.software_entries[i] is Dictionary and int(Dictionary(view.software_entries[i]).get("payload_index", -1)) == 0:
			slot_index = i
			break
	if slot_index < 0:
		_fail("Module payload was not visible in torso detail software slots.")
	var remove_pos: Vector2 = view._remove_rect_for_slot(view._slot_rect("software", slot_index)).get_center()
	var hit: Dictionary = view._slot_hit(remove_pos)
	if String(hit.get("action", "")) != "delete":
		_fail("Delete hot zone should be detected before normal slot selection.")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = remove_pos
	view._gui_input(event)
	if not Array(unit_bp.get("slot_payloads", [])).is_empty():
		_fail("Real delete click did not remove the module payload.")
	if not Array(unit_bp.get("module_bindings", [])).is_empty():
		_fail("Real delete click did not clear module binding.")
	var result_nodes: Array = Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", []))
	var result_limb: Dictionary = Dictionary(result_nodes[limb_a])
	if result_limb.has("module") or result_limb.has("modules") or result_limb.has("attack_key"):
		_fail("Real delete click did not clear node module fields.")
	if not main.editor_bound_module_tryout.is_empty():
		_fail("Real delete click did not clear tryout preview.")
	print("MODULE_PAYLOAD_DELETE_REAL_UI_PROBE ok")
	quit()
