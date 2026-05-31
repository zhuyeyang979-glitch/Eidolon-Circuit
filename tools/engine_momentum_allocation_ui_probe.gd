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


func _contains_banned(text: String) -> bool:
	var lower := text.to_lower()
	for banned in ["engine_momentum", "legacy", "attack group", "damage unit", "child visual"]:
		if lower.contains(banned):
			return true
	return false


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
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Allocation view is not visible.")
	if view.size.x < 600.0 or view.size.y < 420.0:
		_fail("Allocation view is too small for readable layout.")
	var combined := "%s\n%s" % [String(view.title), String(view.subtitle)]
	if not combined.contains("动力"):
		_fail("Chinese UI should expose power allocation wording: %s" % combined)
	if _contains_banned(combined):
		_fail("Allocation UI exposed old engineering wording: %s" % combined)
	var data: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var has_booster := false
	var has_limb := false
	for entry in Array(data.get("entries", [])):
		if not (entry is Dictionary):
			continue
		var entry_text := "%s %s %s" % [String(Dictionary(entry).get("kind", "")), String(Dictionary(entry).get("label", "")), String(Dictionary(entry).get("line", ""))]
		if _contains_banned(entry_text):
			_fail("Allocation entry exposed old wording: %s" % entry_text)
		has_booster = has_booster or String(Dictionary(entry).get("kind", "")).begins_with("booster")
		has_limb = has_limb or String(Dictionary(entry).get("kind", "")) == "limb"
	if not has_booster or not has_limb:
		_fail("Allocation UI should include thrust and action limb entries.")
	print("ENGINE_POWER_ALLOCATION_UI_PROBE ok entries=%d" % Array(data.get("entries", [])).size())
	quit()
