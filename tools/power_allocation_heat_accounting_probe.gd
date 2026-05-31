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
		if main._thruster_drive_allocation_min_for_part(main._selected_component("hero", "booster", i)) > 0.0:
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
	var torso_node := 0
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var data: Dictionary = main._engine_momentum_allocation_data(unit_bp, torso_node, 0)
	if data.is_empty():
		_fail("Allocation data is empty.")
	var display_entries: Array = Array(data.get("display_entries", []))
	if display_entries.is_empty():
		_fail("Display entries are empty.")
	var has_engine_heat := false
	var display_heat_sum := 0.0
	var display_ratio_sum := 0.0
	for raw_entry in display_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		display_heat_sum += maxf(0.0, float(entry.get("heat_load", 0.0)))
		display_ratio_sum += maxf(0.0, float(entry.get("heat_ratio", 0.0)))
		if String(entry.get("kind", "")) == "engine_heat":
			has_engine_heat = true
	if not has_engine_heat:
		_fail("Engine idle heat row is missing from display entries.")
	var heat_used := maxf(0.0, float(data.get("heat_used", 0.0)))
	var heat_ratio := maxf(0.0, float(data.get("heat_ratio", 0.0)))
	if absf(display_heat_sum - heat_used) > 0.02:
		_fail("Displayed heat rows %.3f do not add to total heat %.3f." % [display_heat_sum, heat_used])
	if float(data.get("cooling_pool", 0.0)) > 0.0 and absf(display_ratio_sum - heat_ratio) > 0.002:
		_fail("Displayed heat ratios %.4f do not add to total ratio %.4f." % [display_ratio_sum, heat_ratio])
	main._open_engine_momentum_allocation_for_payload(0)
	if main.engine_momentum_allocation_view == null or not main.engine_momentum_allocation_view.visible:
		_fail("Detailed allocation panel did not open.")
	var view_has_engine_heat := false
	for raw_entry in Array(main.engine_momentum_allocation_view.entries):
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == "engine_heat":
			view_has_engine_heat = true
	if not view_has_engine_heat:
		_fail("Detailed panel did not receive engine heat row.")
	print("POWER_ALLOCATION_HEAT_ACCOUNTING_PROBE ok heat=%.2f ratio=%.3f rows=%d" % [heat_used, heat_ratio, display_entries.size()])
	quit()
