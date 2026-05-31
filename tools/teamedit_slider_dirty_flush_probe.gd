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


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_canvas_mode = "blank"
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main.editor_panel_mode = "parts"
	main._open_engine_momentum_allocation_for_payload(0)
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var booster_id := _first_id(data, "booster")
	var limb_id := _first_id(data, "limb")
	if booster_id == "" or limb_id == "":
		_fail("Missing booster or limb allocation entry.")
	main.editor_update_ui_count = 0
	main.editor_visual_refresh_count = 0
	main.editor_allocation_light_refresh_count = 0
	main.editor_allocation_full_refresh_count = 0
	main._set_engine_momentum_allocation_ratio(booster_id, 0.2)
	if int(main.editor_allocation_light_refresh_count) != 0:
		_fail("Readonly booster drag should not trigger a refresh.")
	main._set_engine_momentum_allocation_ratio(limb_id, 0.2)
	main._set_engine_momentum_allocation_ratio(limb_id, 0.3)
	if int(main.editor_update_ui_count) != 0 or int(main.editor_visual_refresh_count) != 0:
		_fail("Slider drag path triggered full UI/board refresh.")
	main._finish_engine_momentum_allocation_drag(limb_id)
	if int(main.editor_allocation_full_refresh_count) != 1:
		_fail("Slider release did not perform exactly one full refresh.")
	print("TEAMEDIT_SLIDER_DIRTY_FLUSH_PROBE ok light=%d full=%d ui=%d" % [int(main.editor_allocation_light_refresh_count), int(main.editor_allocation_full_refresh_count), int(main.editor_update_ui_count)])
	quit()
