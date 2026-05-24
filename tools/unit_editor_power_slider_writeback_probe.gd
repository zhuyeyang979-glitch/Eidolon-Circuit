extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		if bool(predicate.call(Dictionary(main._catalog_for("hero", slot)[i]))):
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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main.editor_open_torso_node_index = 0
	main.editor_topology_node_index = 0
	main._update_editor_ui(true)
	var entry := {}
	var booster_entry := {}
	for raw_entry in main.editor_power_dock_view.entries:
		if not (raw_entry is Dictionary):
			continue
		if String(Dictionary(raw_entry).get("kind", "")) == "booster_drive":
			booster_entry = Dictionary(raw_entry)
		if String(Dictionary(raw_entry).get("kind", "")) == "limb" and entry.is_empty():
			entry = Dictionary(raw_entry)
	if booster_entry.is_empty():
		_fail("No booster drive entry found.")
	var booster_id := String(booster_entry.get("id", ""))
	var booster_expected := main._engine_allocation_clamped_momentum_from_entries(Array(main.editor_power_dock_view.entries), booster_id, main.editor_power_dock_view.engine_output * 0.12, main.editor_power_dock_view.engine_output)
	main._set_engine_momentum_allocation_ratio(booster_id, 0.12)
	var booster_payload_index := int(booster_id.get_slice(":", 1))
	var after_booster_payloads: Array = Array(main._editor_current_blueprint().get("slot_payloads", []))
	if booster_payload_index < 0 or booster_payload_index >= after_booster_payloads.size():
		_fail("Booster payload index was not valid after readonly attempt.")
	if absf(float(Dictionary(after_booster_payloads[booster_payload_index]).get("thruster_drive_allocated_momentum", -1.0)) - booster_expected) > 0.01:
		_fail("Booster dock slider did not write drive allocation.")
	if entry.is_empty():
		_fail("No limb allocation entry found.")
	var entry_id := String(entry.get("id", ""))
	main._set_engine_momentum_allocation_ratio(entry_id, 0.12)
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var expected: float = main._engine_allocation_clamped_momentum_from_entries(Array(main.editor_power_dock_view.entries), entry_id, main.editor_power_dock_view.engine_output * 0.12, main.editor_power_dock_view.engine_output)
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	if bindings.is_empty() or not (bindings[0] is Dictionary):
		_fail("Limb binding missing after dock writeback.")
	var by_node: Dictionary = Dictionary(bindings[0]).get("allocated_limb_momentum_by_node", {})
	var actual := -1.0
	for value in by_node.values():
		actual = float(value)
		break
	if absf(actual - expected) > 0.5:
		_fail("Power dock slider writeback did not update limb momentum.")
	print("UNIT_EDITOR_POWER_SLIDER_WRITEBACK_PROBE ok limb=%.2f" % actual)
	quit()
