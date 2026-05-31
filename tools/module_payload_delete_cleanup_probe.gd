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


func _build_unit(main, module_index: int) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	var limb_node: Dictionary = Dictionary(nodes[limb_a]).duplicate(true)
	limb_node["modules"] = [module_index]
	limb_node["module"] = module_index
	limb_node["attack_key"] = 1
	nodes[limb_a] = limb_node
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "module", "module": module_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit_bp["module_bindings"] = [
		{"software_slot_index": 0, "module_index": module_index, "attack_key": 1, "target_kind": "limb", "target_nodes": [limb_a, limb_b], "target_torso_node": torso, "allocated_limb_momentum_by_node": {str(limb_a): 12.0, str(limb_b): 12.0}, "joint_drive_allocation_by_node": {str(limb_a): 12.0, str(limb_b): 12.0}},
		{"software_slot_index": 1, "module_index": module_index, "attack_key": 2, "target_kind": "limb", "target_nodes": [limb_a, limb_b], "target_torso_node": torso, "allocated_limb_momentum_by_node": {str(limb_a): 16.0, str(limb_b): 16.0}, "joint_drive_allocation_by_node": {str(limb_a): 16.0, str(limb_b): 16.0}},
	]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var module_index: int = _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
	var unit_bp: Dictionary = _build_unit(main, module_index)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = 0
	main.editor_bound_module_tryout = {"attack_key": 1, "target_nodes": [1, 2], "profile": "two_link_forward_snap"}
	main.editor_pending_module_binding = {"payload_index": 0, "module_index": module_index, "target_selected": true, "target_nodes": [1, 2]}
	main._remove_torso_payload_at(0)
	var bindings_after_first: Array = Array(unit_bp.get("module_bindings", []))
	if bindings_after_first.size() != 1:
		_fail("Deleting one module payload should remove only that payload binding.")
	if int(Dictionary(bindings_after_first[0]).get("software_slot_index", -1)) != 0:
		_fail("Remaining module binding was not shifted after payload delete.")
	if not main.editor_pending_module_binding.is_empty():
		_fail("Deleting pending module payload should clear pending binding.")
	if not main.editor_bound_module_tryout.is_empty():
		_fail("Deleting tryout module payload should clear current tryout.")
	main.editor_bound_module_tryout = {"attack_key": 2, "target_nodes": [1, 2], "profile": "two_link_forward_snap"}
	main._remove_torso_payload_at(0)
	if not Array(unit_bp.get("module_bindings", [])).is_empty():
		_fail("Deleting final module payload should clear all module bindings.")
	var nodes: Array = Array(Dictionary(unit_bp.get("custom_topology", {})).get("nodes", []))
	var limb_a: Dictionary = Dictionary(nodes[1])
	if limb_a.has("module") or limb_a.has("modules") or limb_a.has("attack_key"):
		_fail("Deleting final module payload should clear node module and attack-key fields.")
	if not main.editor_bound_module_tryout.is_empty():
		_fail("Deleting final module payload should clear current tryout.")
	print("MODULE_PAYLOAD_DELETE_CLEANUP_PROBE ok")
	quit()
