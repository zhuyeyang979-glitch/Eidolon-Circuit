extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _find(main, slot: String, predicate: Callable) -> int:
	for i in range(main._catalog_for("hero", slot).size()):
		var part: Dictionary = main._selected_component("hero", slot, i)
		if bool(predicate.call(part)):
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._catalog_for("hero", "module")[i]
		if String(part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_unit(main) -> Dictionary:
	var unit: Dictionary = main._make_editor_blank_blueprint("hero")
	var torso_index := _find(main, "muscle", func(part: Dictionary) -> bool: return main._component_is_torso(part))
	var engine_index := _find(main, "engine", func(part: Dictionary) -> bool: return main._engine_momentum_output_for_part(part) > 100.0)
	var booster_index := _find(main, "booster", func(part: Dictionary) -> bool: return main._thruster_drive_demand_for_part(part) > 0.0)
	var module_index := _two_link_module(main)
	if torso_index < 0 or engine_index < 0 or booster_index < 0 or module_index < 0:
		_fail("Missing torso, engine, booster, or two-link module.")
		return {}
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
	var unit: Dictionary = main._editor_current_blueprint()
	var torso := int(Dictionary(Array(unit.get("slot_payloads", []))[0]).get("torso_node", 0))
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit, torso)
	main._refresh_engine_momentum_allocation_view()
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Power allocation panel did not open.")
		return
	var limb_index := -1
	for i in range(view.entries.size()):
		if view.entries[i] is Dictionary and String(Dictionary(view.entries[i]).get("kind", "")) == "limb":
			limb_index = i
			break
	if limb_index < 0:
		_fail("Missing bound limb allocation row.")
		return
	var limb_entry: Dictionary = view.entries[limb_index]
	var full_rect: Rect2 = view._entry_full_slider_rect(limb_index)
	var active_rect: Rect2 = view._entry_slider_rect(limb_index)
	var min_momentum := float(limb_entry.get("min_momentum", 0.0))
	var max_momentum := float(limb_entry.get("max_momentum", 0.0))
	var pool := float(view.engine_output)
	if max_momentum <= min_momentum or pool <= 0.0:
		_fail("Invalid limb range or engine pool.")
		return
	if active_rect.size.x >= full_rect.size.x - 0.5:
		_fail("Limb slider active track should be shorter than the full engine-pool rail when limb range is below pool.")
		return
	if active_rect.position.x < full_rect.position.x - 0.5 or active_rect.end.x > full_rect.end.x + 0.5:
		_fail("Limb slider active track must stay inside the full budget rail.")
		return
	var captured: Array = [false, "", 0.0]
	view.allocation_changed.connect(func(entry_id: String, ratio: float) -> void:
		captured[0] = true
		captured[1] = entry_id
		captured[2] = ratio
	)
	view.last_emitted_ratios.clear()
	view._emit_slider_change(String(limb_entry.get("id", "")), active_rect.position + Vector2(active_rect.size.x, active_rect.size.y * 0.5))
	if not bool(captured[0]):
		_fail("Slider end did not emit allocation change.")
		return
	var expected_ratio := max_momentum / maxf(1.0, pool)
	if absf(float(captured[2]) - expected_ratio) > 0.015:
		_fail("Slider right end should map to limb max momentum ratio %.3f, got %.3f." % [expected_ratio, float(captured[2])])
		return
	print("POWER_ALLOCATION_LIMB_SLIDER_RANGE_LENGTH_PROBE ok active=%.1f full=%.1f range=%.1f-%.1f pool=%.1f" % [active_rect.size.x, full_rect.size.x, min_momentum, max_momentum, pool])
	quit()
