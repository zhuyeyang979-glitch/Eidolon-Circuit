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
		if main._thruster_drive_demand_for_part(main._selected_component("hero", "booster", i)) > 0.0:
			return i
	return -1


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._catalog_for("hero", "module")[i]
		if String(part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var torso_index := _first_torso(main)
	var engine_index := _first_engine(main)
	var booster_index := _first_booster(main)
	var module_index := _two_link_module(main)
	if torso_index < 0 or engine_index < 0 or booster_index < 0 or module_index < 0:
		_fail("Missing torso, engine, booster, or two-link module.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "L1", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "L2", "limb_muscle", 0, Vector2.RIGHT)
	var by_node := {str(limb_a): 8.0, str(limb_b): 8.0}
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "booster", "booster": booster_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 2,
		"module_index": module_index,
		"attack_key": 1,
		"target_kind": "limb",
		"root_index": limb_a,
		"target_nodes": [limb_a, limb_b],
		"target_torso_node": torso,
		"allocated_limb_momentum_by_node": by_node,
		"joint_drive_allocation_by_node": by_node.duplicate(true),
	}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_open_torso_node_index = torso
	main._activate_engine_allocation_target_for_torso(unit_bp, torso)
	main._refresh_engine_momentum_allocation_view()
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Power allocation panel did not open.")
	var side: Rect2 = view._side_rect()
	var limb_rows := 0
	var booster_rows := 0
	for i in range(view.entries.size()):
		if not (view.entries[i] is Dictionary):
			continue
		var entry: Dictionary = view.entries[i]
		var slider: Rect2 = view._entry_slider_rect(i)
		if slider.position.x < side.position.x or slider.end.x > side.end.x:
			_fail("Entry %s slider is not in the unified right-side row list." % String(entry.get("id", "")))
		if view._entry_row_rect(i).size.y < 104.0:
			_fail("Entry %s row is too tight for drive and heat bars." % String(entry.get("id", "")))
		if String(entry.get("kind", "")) == "limb":
			limb_rows += 1
			if not String(entry.get("group_id", "")).begins_with("binding:"):
				_fail("Limb row is missing its bound group id.")
		if String(entry.get("kind", "")).begins_with("booster"):
			booster_rows += 1
			if float(entry.get("momentum", 0.0)) <= 0.0:
				if String(entry.get("kind", "")) != "booster_boost_brake":
					_fail("Booster drive row should display positive allocation.")
	if limb_rows < 2:
		_fail("Expected at least two bound limb sliders in the power allocation panel.")
	if booster_rows < 1:
		_fail("Expected booster allocation rows in the power allocation panel.")
	print("POWER_ALLOCATION_PANEL_LIMB_SLIDER_ROWS_PROBE ok limbs=%d boosters=%d" % [limb_rows, booster_rows])
	quit()
