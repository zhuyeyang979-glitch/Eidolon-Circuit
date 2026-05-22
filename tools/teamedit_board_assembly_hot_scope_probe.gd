extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_index(main, slot_key: String) -> int:
	var role_key: String = main.ROLE_ORDER[main.editor_role_index]
	var catalog: Array = main._catalog_for(role_key, slot_key)
	return 0 if not catalog.is_empty() else -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._start_blank_topology()
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	main.editor_dirty_flags = 0
	var joint_index := _first_index(main, "joint")
	var limb_index := _first_index(main, "limb_muscle")
	if joint_index < 0 or limb_index < 0:
		_fail("Missing joint or limb catalog entry for assembly probe.")
		return
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_gpu_submit := int(main.gpu_geometry_query_submit_count)
	main.hot_path_profiler.begin_interaction("teamedit.assembly_hot_scope")
	main.hot_path_profiler.begin_frame()
	main._drop_catalog_part_on_board("joint", joint_index, Vector2(300.0, 240.0))
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.begin_frame()
	main._drop_catalog_part_on_board("limb_muscle", limb_index, Vector2(346.0, 240.0))
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	var unit_bp: Dictionary = main._editor_current_blueprint()
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = topology.get("nodes", [])
	if nodes.size() >= 2:
		main.hot_path_profiler.begin_frame()
		main._try_magnetic_link_for_node(unit_bp, nodes.size() - 1)
		main._mark_editor_board_interaction_dirty("probe.manual_link")
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
		main.hot_path_profiler.begin_frame()
		main._unlink_joint_edges(unit_bp, nodes.size() - 1)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.assembly_hot_scope")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.assembly_hot_scope")
	var leaves: Array = main.hot_path_profiler.interaction_hot_scopes("teamedit.assembly_hot_scope", 5, true)
	var leaf_texts: Array = []
	for leaf in leaves:
		if leaf is Dictionary:
			leaf_texts.append("%s:%.2fms" % [String(Dictionary(leaf).get("name", "")), float(Dictionary(leaf).get("usec", 0)) / 1000.0])
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var gpu_delta := int(main.gpu_geometry_query_submit_count) - before_gpu_submit
	if catalog_delta != 0:
		_fail("Board assembly refreshed catalog cards: %d" % catalog_delta)
		return
	if gpu_delta != 0:
		_fail("Board assembly submitted battle/GPU geometry queries: %d" % gpu_delta)
		return
	print("TEAMEDIT_BOARD_ASSEMBLY_HOT_SCOPE_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d hot=%s leaf=%s" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_delta,
		String(stats.get("hot_scope", "")),
		",".join(leaf_texts),
	])
	quit(0)
