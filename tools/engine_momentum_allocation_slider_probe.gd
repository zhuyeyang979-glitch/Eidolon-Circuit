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
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{"software_slot_index": 2, "module_index": module_index, "attack_key": 1, "target_kind": "limb", "target_nodes": [limb_a, limb_b], "target_torso_node": torso, "binding_valid_note": "OK"}]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _first_id(data: Dictionary, kind: String) -> String:
	for entry in Array(data.get("entries", [])):
		if entry is Dictionary and String(Dictionary(entry).get("kind", "")) == kind:
			return String(Dictionary(entry).get("id", ""))
	return ""


func _first_entry(data: Dictionary, kind: String) -> Dictionary:
	for entry in Array(data.get("entries", [])):
		if entry is Dictionary and String(Dictionary(entry).get("kind", "")) == kind:
			return Dictionary(entry)
	return {}


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
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var pool := float(data.get("engine_output", 0.0))
	var booster_entry := _first_entry(data, "booster_drive")
	var limb_entry := _first_entry(data, "limb")
	var booster_id := String(booster_entry.get("id", ""))
	var limb_id := String(limb_entry.get("id", ""))
	if booster_id == "" or limb_id == "":
		_fail("Missing booster or limb allocation entry.")
	if bool(booster_entry.get("readonly", false)):
		_fail("Booster drive allocation entry should be adjustable.")
	var requested_ratio := 0.25
	main._set_engine_momentum_allocation_ratio(booster_id, requested_ratio)
	var payloads: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	var booster_payload: Dictionary = payloads[1]
	var after_booster: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var after_booster_entry := _first_entry(after_booster, "booster_drive")
	var expected_booster := main._engine_allocation_clamped_momentum_from_entries(Array(data.get("entries", [])), booster_id, pool * requested_ratio, pool)
	if absf(float(after_booster_entry.get("momentum", -1.0)) - expected_booster) > 0.01:
		_fail("Booster drive allocation did not change to expected clamped momentum.")
	if absf(float(booster_payload.get("thruster_drive_allocated_momentum", -1.0)) - expected_booster) > 0.01:
		_fail("Booster drive allocation did not write payload.")
	main._set_engine_momentum_allocation_ratio(limb_id, 0.20)
	var bindings: Array = Array(main._editor_current_blueprint().get("module_bindings", []))
	var binding: Dictionary = bindings[0]
	var by_node: Dictionary = binding.get("allocated_limb_momentum_by_node", {})
	if by_node.is_empty():
		_fail("Limb allocation did not write per-node map.")
	var expected_momentum := main._engine_allocation_clamped_momentum_from_entries(Array(after_booster.get("entries", [])), limb_id, pool * 0.20, pool)
	var found := false
	for value in by_node.values():
		if absf(float(value) - expected_momentum) <= 0.01:
			found = true
	if not found:
		_fail("Limb allocation map did not contain expected clamped momentum %.3f: %s" % [expected_momentum, str(by_node)])
	var stats: Dictionary = main._editor_current_stats()
	var required := float(stats.get("drive_demand_total", stats.get("engine_momentum_required", 0.0)))
	if required <= 0.0:
		_fail("Allocation did not affect engine demand.")
	print("ENGINE_POWER_ALLOCATION_SLIDER_PROBE ok pool=%.1f required=%.1f" % [pool, required])
	quit()
