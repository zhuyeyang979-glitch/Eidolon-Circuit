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


func _first_engine(main) -> int:
	for i in range(main._catalog_for("hero", "engine").size()):
		if main._engine_momentum_output_for_part(main._selected_component("hero", "engine", i)) > 0.0:
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
	var engine_index := _first_engine(main)
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 1,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": {str(limb_a): 4.0, str(limb_b): 4.0},
		"joint_drive_allocation_by_node": {str(limb_a): 4.0, str(limb_b): 4.0},
		"joint_drive_allocation_total": 8.0,
		"binding_valid_note": "OK",
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._refresh_unit_editor_power_allocation_topbar()
	var limb_entry := {}
	for raw_entry in main.editor_power_topbar_view.entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "limb":
			limb_entry = Dictionary(raw_entry)
			break
	if limb_entry.is_empty():
		_fail("No bound limb allocation entry found.")
	var entry_id := String(limb_entry.get("id", ""))
	main._set_engine_momentum_allocation_ratio(entry_id, 0.20)
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	var binding: Dictionary = Dictionary(bindings[0])
	var by_node: Dictionary = Dictionary(binding.get("allocated_limb_momentum_by_node", {}))
	if not by_node.has(str(int(limb_entry.get("node_index", -1)))):
		_fail("Slider did not write canonical allocated_limb_momentum_by_node.")
	if not Dictionary(binding.get("joint_drive_allocation_by_node", {})).has(str(int(limb_entry.get("node_index", -1)))):
		_fail("Slider did not keep joint_drive_allocation_by_node synchronized.")
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	var runtime_binding: Dictionary = Dictionary(runtime_bindings[0])
	if Dictionary(runtime_binding.get("allocated_limb_momentum_by_node", {})).is_empty():
		_fail("Runtime binding did not carry slider allocation values.")
	print("POWER_SLIDER_UPDATES_RUNTIME_BINDING_PROBE ok")
	quit()
