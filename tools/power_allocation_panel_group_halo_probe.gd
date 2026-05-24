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


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		var part: Dictionary = main._catalog_for("hero", "module")[i]
		if String(part.get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _make_bound_unit(main) -> Dictionary:
	var torso_index := _first_torso(main)
	var engine_index := _first_engine(main)
	var module_index := _two_link_module(main)
	if torso_index < 0 or engine_index < 0 or module_index < 0:
		_fail("Missing torso, engine, or two-link module.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), torso_index)
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "L1", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "L2", "limb_muscle", 0, Vector2.RIGHT)
	var by_node := {str(limb_a): 8.0, str(limb_b): 8.0}
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["slot_payloads"] = [
		{"kind": "engine", "engine": engine_index, "torso_node": torso},
		{"kind": "module", "module": module_index, "torso_node": torso},
	]
	unit_bp["module_bindings"] = [{
		"software_slot_index": 1,
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
	return {"unit": unit_bp, "torso": torso}


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var setup := _make_bound_unit(main)
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = Dictionary(setup["unit"])
	main.editor_open_torso_node_index = int(setup["torso"])
	main._activate_engine_allocation_target_for_torso(main.editor_working_blueprint, int(setup["torso"]))
	main._refresh_engine_momentum_allocation_view()
	var view = main.engine_momentum_allocation_view
	if view == null or not view.visible:
		_fail("Power allocation panel did not open.")
	if view.allocation_groups.is_empty():
		_fail("Power allocation panel has no bound limb group halo payloads.")
	var group: Dictionary = view.allocation_groups[0]
	var halo_rect: Rect2 = view._allocation_group_screen_rect(group)
	if halo_rect.size.x <= 1.0 or halo_rect.size.y <= 1.0:
		_fail("Bound limb group halo has no visible silhouette rect.")
	var hit_id: String = view._allocation_group_id_at(halo_rect.get_center())
	if hit_id != String(group.get("id", "")):
		_fail("Clicking the allocation-page limb halo does not select the bound group.")
	print("POWER_ALLOCATION_PANEL_GROUP_HALO_PROBE ok group=%s rect=%s" % [String(group.get("id", "")), str(halo_rect)])
	quit()
