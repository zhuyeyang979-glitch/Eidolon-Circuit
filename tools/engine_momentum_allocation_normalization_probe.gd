extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(main._selected_component("hero", slot, i))):
			return i
	return -1


func _module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_allocated_momentum_for_part(part) > 0.0)
	var module_index := _module(main)
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [module_index])
	var limb_b: int = main._append_directed_component_node("hero", unit, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit["blank_canvas"] = false
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso, "allocated_momentum": 9999.0},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 2,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": {str(limb_a): 9999.0, str(limb_b): 9999.0},
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
	main._open_engine_momentum_allocation_for_payload(0)
	var before: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	if float(before.get("used_ratio", 0.0)) <= 1.0:
		_fail("Probe setup should start over budget.")
	main._equalize_engine_momentum_allocation()
	var after: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	if float(after.get("used_ratio", 0.0)) > 1.001:
		_fail("Equalize did not normalize allocation: %.4f" % float(after.get("used_ratio", 0.0)))
	if Array(after.get("entries", [])).is_empty():
		_fail("Equalize removed allocation entries.")
	var payloads: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	if payloads.size() < 2 or not (payloads[1] is Dictionary):
		_fail("Booster payload missing after equalize.")
	var booster_payload: Dictionary = payloads[1]
	if booster_payload.has("allocated_momentum") and absf(float(booster_payload.get("allocated_momentum", 0.0)) - 9999.0) > 0.01:
		_fail("Equalize should not rewrite readonly booster payload allocation alias.")
	for raw_entry in Array(after.get("entries", [])):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")).begins_with("booster") and float(Dictionary(raw_entry).get("momentum", 0.0)) <= 0.0 and String(Dictionary(raw_entry).get("kind", "")) == "booster_drive":
			_fail("Booster drive entry should remain present after equalize.")
	print("ENGINE_POWER_ALLOCATION_NORMALIZATION_PROBE ok before=%.2f after=%.2f" % [float(before.get("used_ratio", 0.0)), float(after.get("used_ratio", 0.0))])
	quit()
