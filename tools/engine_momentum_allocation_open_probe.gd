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


func _first_booster(main) -> int:
	for i in range(main._catalog_for("hero", "booster").size()):
		if main._thruster_allocated_momentum_for_part(main._selected_component("hero", "booster", i)) > 0.0:
			return i
	return -1


func _first_two_link(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var module_index := _first_two_link(main)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "ARM A", "limb_muscle", 0, Vector2.RIGHT, [module_index])
	var limb_b: int = main._append_directed_component_node("hero", unit, nodes, edges, limb_a, "ARM B", "limb_muscle", 0, Vector2.RIGHT)
	unit["blank_canvas"] = false
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": _first_engine(main), "torso_node": torso},
		{"kind": "booster", "booster": _first_booster(main), "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 2,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"binding_valid_note": "OK",
	}]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main._update_editor_ui()
	main._open_engine_momentum_allocation_for_payload(0)
	if main.engine_momentum_allocation_view == null or not main.engine_momentum_allocation_view.visible:
		_fail("Engine allocation panel did not open.")
	if String(main.engine_momentum_allocation_view.title) != "动力分配":
		_fail("Unexpected allocation title: %s" % String(main.engine_momentum_allocation_view.title))
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	if float(data.get("engine_output", 0.0)) <= 0.0:
		_fail("Allocation pool should be positive.")
	if Array(data.get("entries", [])).size() < 2:
		_fail("Allocation panel should expose booster and limb entries.")
	print("ENGINE_POWER_ALLOCATION_OPEN_PROBE ok entries=%d pool=%.1f" % [Array(data.get("entries", [])).size(), float(data.get("engine_output", 0.0))])
	quit()
