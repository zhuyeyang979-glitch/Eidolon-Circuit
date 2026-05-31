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


func _two_link_module(main) -> int:
	for i in range(main._catalog_for("hero", "module").size()):
		if String(Dictionary(main._catalog_for("hero", "module")[i]).get("module_action_profile", "")) == "two_link_forward_snap":
			return i
	return -1


func _build_bound_unit(main) -> Dictionary:
	var module_index := _two_link_module(main)
	if module_index < 0:
		_fail("Two-Link module missing.")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.50), _first_torso(main))
	var limb_a: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "A", "limb_muscle", 0, Vector2.RIGHT)
	var limb_b: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, limb_a, "B", "limb_muscle", 0, Vector2.RIGHT)
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	unit_bp["slot_payloads"] = [{"kind": "module", "module": module_index, "software_slot_index": 0, "torso_node": torso}]
	unit_bp["module_bindings"] = [{"payload_index": 0, "module_index": module_index, "attack_key": 1, "target_nodes": [limb_a, limb_b]}]
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	main._topology_update_local_pose_fields("hero", unit_bp)
	return unit_bp


func _leaf_scope_text(main, interaction: String) -> String:
	var leaves: Array = main.hot_path_profiler.interaction_hot_scopes(interaction, 7, true)
	var texts: Array = []
	for leaf in leaves:
		if leaf is Dictionary:
			texts.append("%s:%.2fms" % [String(Dictionary(leaf).get("name", "")), float(Dictionary(leaf).get("usec", 0)) / 1000.0])
	return ",".join(texts)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_board_tool = "pose"
	main.editor_working_role_key = "hero"
	main.editor_canvas_mode = "blank"
	main.editor_working_blueprint = _build_bound_unit(main)
	main._refresh_editor_visual_views({}, false)
	for _warm in range(4):
		main._tick_editor_visuals(1.0 / 60.0)
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var nodes: Array = Dictionary(unit_bp.get("custom_topology", {})).get("nodes", [])
	var root_index := 1
	var pivot: Vector2 = main._topology_socket_position_by_id("hero", unit_bp, nodes, Dictionary(unit_bp.get("custom_topology", {})).get("edges", []), root_index, "root_joint")
	var start_local := main._topology_position_to_board_local(pivot + Vector2.RIGHT * 0.12)
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_stats := int(main.editor_compute_unit_stats_count)
	var before_gpu := int(main.gpu_geometry_query_submit_count)
	var before_full_undo := int(main.editor_undo_full_snapshot_count)
	main.hot_path_profiler.begin_interaction("teamedit.bound_pose_drag")
	main.hot_path_profiler.begin_frame()
	if not main._start_editor_pose_drag(unit_bp, root_index, start_local, [1, 2]):
		_fail("Could not start bound pose drag.")
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	for i in range(12):
		main.hot_path_profiler.begin_frame()
		var angle := 0.35 + float(i) * 0.045
		for j in range(3):
			var local := main._topology_position_to_board_local(pivot + Vector2(cos(angle + float(j) * 0.01), sin(angle + float(j) * 0.01)) * 0.14)
			main._update_editor_pose_drag(unit_bp, local)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.begin_frame()
	main._finish_editor_pose_drag(unit_bp)
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.bound_pose_drag")
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var stats_delta := int(main.editor_compute_unit_stats_count) - before_stats
	var gpu_delta := int(main.gpu_geometry_query_submit_count) - before_gpu
	var full_undo_delta := int(main.editor_undo_full_snapshot_count) - before_full_undo
	if catalog_delta != 0:
		_fail("Pose drag refreshed catalog cards: %d" % catalog_delta)
	if gpu_delta != 0:
		_fail("Pose drag submitted GPU geometry queries: %d" % gpu_delta)
	if full_undo_delta != 0:
		_fail("Pose drag used full blueprint undo snapshot: %d" % full_undo_delta)
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.bound_pose_drag")
	var p95_ms := float(stats.get("p95_usec", 0)) / 1000.0
	var max_ms := float(stats.get("max_usec", 0)) / 1000.0
	if p95_ms > 12.0 or max_ms > 20.0:
		_fail("Bound pose drag too slow p95=%.2f max=%.2f hot=%s leaf=%s" % [p95_ms, max_ms, String(stats.get("hot_scope", "")), _leaf_scope_text(main, "teamedit.bound_pose_drag")])
	print("TEAMEDIT_BOUND_POSE_DRAG_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d stats_delta=%d gpu_delta=%d full_undo_delta=%d apply=%d coalesced=%d hot=%s leaf=%s" % [
		p95_ms,
		max_ms,
		catalog_delta,
		stats_delta,
		gpu_delta,
		full_undo_delta,
		int(main.editor_pose_drag_apply_count),
		int(main.editor_pose_drag_coalesced_count),
		String(stats.get("hot_scope", "")),
		_leaf_scope_text(main, "teamedit.bound_pose_drag"),
	])
	quit(0)
