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
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_demand_for_part(part) > 0.0)
	var module_index := _module(main)
	if torso_index < 0 or engine_index < 0 or booster_index < 0 or module_index < 0:
		_fail("Missing required catalog parts.")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit["blank_canvas"] = false
	unit["role"] = "hero"
	unit["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 2,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": {str(limb_a): 8.0, str(limb_b): 8.0},
		"joint_drive_allocation_by_node": {str(limb_a): 8.0, str(limb_b): 8.0},
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
	main.editor_panel_mode = "parts"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	var unit: Dictionary = main._editor_current_blueprint()
	var torso := int(Dictionary(unit.get("slot_payloads", [])[0]).get("torso_node", 0))
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit, torso)
	main._refresh_engine_momentum_allocation_view()
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Power allocation panel did not open.")
	var limb_entry := {}
	var booster_entry := {}
	for raw_entry in view.entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if String(entry.get("kind", "")) == "limb" and limb_entry.is_empty():
			limb_entry = entry
		elif String(entry.get("kind", "")).begins_with("booster") and booster_entry.is_empty():
			booster_entry = entry
	if limb_entry.is_empty() or booster_entry.is_empty():
		_fail("Need limb and booster entries.")
	var limb_id := String(limb_entry.get("id", ""))
	var booster_id := String(booster_entry.get("id", ""))
	if not view.entry_value_edits.has(limb_id):
		_fail("Editable limb should have a numeric input.")
	if not view.entry_value_edits.has(booster_id):
		_fail("Editable booster allocation row should have a numeric input.")
	var min_value := float(limb_entry.get("min_momentum", 0.0))
	var max_value := float(limb_entry.get("max_momentum", 0.0))
	var requested := clampf((min_value + max_value) * 0.5, min_value, max_value)
	main._set_engine_momentum_allocation_value(limb_id, requested)
	unit = main._editor_current_blueprint()
	var binding: Dictionary = Dictionary(Array(unit.get("module_bindings", []))[0])
	var node_key := str(int(limb_entry.get("node_index", -1)))
	var by_node: Dictionary = Dictionary(binding.get("allocated_limb_momentum_by_node", {}))
	var drive_by_node: Dictionary = Dictionary(binding.get("joint_drive_allocation_by_node", {}))
	if absf(float(by_node.get(node_key, -1.0)) - requested) > 0.01:
		_fail("Numeric input writeback mismatch.")
	if absf(float(drive_by_node.get(node_key, -1.0)) - requested) > 0.01:
		_fail("Numeric input did not sync joint_drive_allocation_by_node.")
	var edit: LineEdit = view.entry_value_edits[limb_id]
	edit.text = "not-a-number"
	view._submit_entry_value_edit(edit.text, limb_id)
	if edit.text == "not-a-number":
		_fail("Invalid numeric text should revert to current value.")
	var booster_min := float(booster_entry.get("min_momentum", 0.0))
	var booster_max := float(booster_entry.get("max_momentum", booster_min))
	var booster_requested := clampf((booster_min + booster_max) * 0.5, booster_min, booster_max)
	main._set_engine_momentum_allocation_value(booster_id, booster_requested)
	unit = main._editor_current_blueprint()
	var booster_payload_index := int(booster_entry.get("payload_index", -1))
	var payload: Dictionary = Dictionary(Array(unit.get("slot_payloads", []))[booster_payload_index])
	if booster_id.begins_with("booster_drive:") and absf(float(payload.get("thruster_drive_allocated_momentum", -1.0)) - booster_requested) > 0.01:
		_fail("Booster drive numeric input did not write thruster_drive_allocated_momentum.")
	if booster_id.begins_with("booster_boost_brake:") and absf(float(payload.get("thruster_boost_brake_allocated_momentum", -1.0)) - booster_requested) > 0.01:
		_fail("Booster boost-brake numeric input did not write thruster_boost_brake_allocated_momentum.")
	print("POWER_ALLOCATION_PANEL_NUMERIC_INPUT_PROBE ok value=%.2f" % requested)
	quit()
