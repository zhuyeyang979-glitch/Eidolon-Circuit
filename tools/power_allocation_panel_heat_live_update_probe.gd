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


func _entry(entries: Array, kind: String) -> Dictionary:
	for raw_entry in entries:
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("kind", "")) == kind:
			return Dictionary(raw_entry)
	return {}


func _heat_sum(view) -> float:
	var total := 0.0
	for raw_entry in Array(view.entries):
		if raw_entry is Dictionary:
			total += maxf(0.0, float(Dictionary(raw_entry).get("heat_load", 0.0)))
	return total


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var cooling_index := _find(main, "cooling", func(part: Dictionary) -> bool: return float(part.get("cooling", part.get("cooling_rate", 0.0))) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_allocation_max_for_part(part) > main._thruster_drive_allocation_min_for_part(part))
	var module_index := _module(main)
	if torso_index < 0 or engine_index < 0 or cooling_index < 0 or booster_index < 0 or module_index < 0:
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
		{"kind": "cooling", "cooling": cooling_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit["module_bindings"] = [{
		"software_slot_index": 3,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": {str(limb_a): 10.0, str(limb_b): 10.0},
		"joint_drive_allocation_by_node": {str(limb_a): 10.0, str(limb_b): 10.0},
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
		return
	var limb_entry := _entry(view.entries, "limb")
	if limb_entry.is_empty():
		_fail("Missing limb entry.")
		return
	var start_heat := float(view.heat_used)
	var min_value := float(limb_entry.get("min_momentum", 0.0))
	var max_value := float(limb_entry.get("max_momentum", min_value))
	var slider_target := clampf((min_value + max_value) * 0.65, min_value, max_value)
	main._set_engine_momentum_allocation_ratio(String(limb_entry.get("id", "")), slider_target / maxf(1.0, float(view.engine_output)))
	limb_entry = _entry(view.entries, "limb")
	if absf(float(limb_entry.get("heat_load", 0.0)) - float(limb_entry.get("momentum", 0.0)) * float(limb_entry.get("heat_coeff", 0.0))) > 0.02:
		_fail("Slider update did not refresh limb heat load.")
		return
	if absf(float(view.heat_used) - _heat_sum(view)) > 0.02:
		_fail("Slider update did not refresh total heat used.")
		return
	var value_target := clampf((min_value + max_value) * 0.35, min_value, max_value)
	main._set_engine_momentum_allocation_value(String(limb_entry.get("id", "")), value_target)
	limb_entry = _entry(view.entries, "limb")
	if absf(float(limb_entry.get("momentum", 0.0)) - value_target) > 0.02:
		_fail("Value input path did not update limb momentum.")
		return
	if absf(float(view.heat_used) - _heat_sum(view)) > 0.02:
		_fail("Value input path did not refresh total heat used.")
		return
	main._equalize_engine_momentum_allocation()
	if absf(float(view.heat_used) - _heat_sum(view)) > 0.02:
		_fail("Equalize did not leave panel heat totals in sync.")
		return
	if absf(float(view.heat_used) - start_heat) < 0.001:
		_fail("Heat total should change after allocation edits.")
		return
	print("POWER_ALLOCATION_PANEL_HEAT_LIVE_UPDATE_PROBE ok heat=%.3f" % float(view.heat_used))
	quit()
