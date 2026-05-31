extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = Dictionary(main._catalog_for("hero", slot)[i])
		if bool(predicate.call(part)):
			return i
	return -1


func _two_link_module(main) -> int:
	return _find(main, "module", func(part: Dictionary) -> bool: return String(part.get("module_action_profile", "")) == "two_link_forward_snap")


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 0.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_boost_brake_allocation_max_for_part(part) > 0.0)
	var module_index := _two_link_module(main)
	if torso_index < 0 or engine_index < 0 or booster_index < 0 or module_index < 0:
		_fail("Missing torso, engine, booster, or two-link module.")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT, [module_index])
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
	}]
	unit["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit)
	return unit


func _adjustable_entries(data: Dictionary) -> Array:
	var result: Array = []
	for raw_entry in Array(data.get("entries", [])):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		if ["booster_drive", "booster_boost_brake", "limb"].has(String(entry.get("kind", ""))):
			result.append(entry)
	return result


func _entry_momentum_by_id(data: Dictionary) -> Dictionary:
	var result := {}
	for entry in _adjustable_entries(data):
		result[String(Dictionary(entry).get("id", ""))] = float(Dictionary(entry).get("momentum", 0.0))
	return result


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main)
	main._open_engine_momentum_allocation_for_payload(0)
	if main.engine_momentum_allocation_view == null or not main.engine_momentum_allocation_view.visible:
		_fail("Allocation detail panel did not open.")
	var before: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var before_by_id := _entry_momentum_by_id(before)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var equalize_local: Vector2 = main.engine_momentum_allocation_view._equalize_rect().get_center()
	click.position = main.engine_momentum_allocation_view.get_global_transform() * equalize_local
	main._input(click)
	var after: Dictionary = main._engine_momentum_allocation_data(main._editor_current_blueprint(), main.editor_engine_allocation_torso_node_index, main.editor_engine_allocation_payload_index)
	var after_entries := _adjustable_entries(after)
	if after_entries.size() < 4:
		_fail("Expected booster drive, booster boost-brake, and limb entries after equalize click.")
	var changed_count := 0
	for entry in after_entries:
		var id := String(Dictionary(entry).get("id", ""))
		var after_momentum := float(Dictionary(entry).get("momentum", 0.0))
		if absf(after_momentum - float(before_by_id.get(id, -9999.0))) > 0.05:
			changed_count += 1
	if changed_count <= 0:
		_fail("Real equalize button click did not change any allocation entry.")
	print("POWER_ALLOCATION_EQUALIZE_BUTTON_REAL_UI_PROBE ok changed=%d entries=%d" % [changed_count, after_entries.size()])
	quit()
