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
	main.editor_open_torso_node_index = 0
	main.editor_topology_node_index = 0
	main._update_editor_ui(true)
	main._open_dashboard_engine_allocation()
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var target_entry := {}
	for raw_entry in Array(data.get("entries", [])):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "booster":
			target_entry = Dictionary(raw_entry)
			break
	if target_entry.is_empty():
		_fail("Need a booster allocation entry for writeback probe.")
	var pool := maxf(1.0, float(data.get("engine_output", 0.0)))
	var requested_ratio := minf(0.2, maxf(0.05, 8.0 / pool))
	main._set_engine_momentum_allocation_ratio(String(target_entry.get("id", "")), requested_ratio)
	var unit: Dictionary = main._editor_current_blueprint()
	var payloads: Array = Array(unit.get("slot_payloads", []))
	var payload_index := int(target_entry.get("payload_index", -1))
	if payload_index < 0 or payload_index >= payloads.size() or not (payloads[payload_index] is Dictionary):
		_fail("Booster payload missing after slider writeback.")
	var expected := pool * requested_ratio
	var actual := float(Dictionary(payloads[payload_index]).get("allocated_momentum", -1.0))
	if absf(actual - expected) > 0.01:
		_fail("Slider writeback mismatch expected %.3f got %.3f." % [expected, actual])
	var summary := String(main.editor_engine_allocation_summary_label.text)
	if summary == "":
		_fail("Dashboard allocation summary should refresh after slider writeback.")
	print("ENGINE_ALLOCATION_SLIDER_WRITEBACK_PROBE ok momentum=%.3f summary=%s" % [actual, summary])
	quit()
