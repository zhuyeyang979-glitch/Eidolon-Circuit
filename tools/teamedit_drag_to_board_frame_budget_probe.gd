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
	var slot_key := "limb_muscle"
	var part_index := _first_index(main, slot_key)
	if part_index < 0:
		slot_key = "muscle"
		part_index = _first_index(main, slot_key)
	if part_index < 0:
		_fail("No topology part available for drag-to-board probe.")
		return
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_stats := int(main.editor_compute_unit_stats_count)
	var before_gpu_submit := int(main.gpu_geometry_query_submit_count)
	var before_visual := int(main.editor_visual_refresh_count)
	main.hot_path_profiler.begin_interaction("teamedit.drag_to_board")
	for i in range(6):
		main.hot_path_profiler.begin_frame()
		main._drop_catalog_part_on_board(slot_key, part_index, Vector2(260.0 + float(i) * 28.0, 220.0))
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.drag_to_board")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.drag_to_board")
	var leaves: Array = main.hot_path_profiler.interaction_hot_scopes("teamedit.drag_to_board", 5, true)
	var leaf_texts: Array = []
	for leaf in leaves:
		if leaf is Dictionary:
			leaf_texts.append("%s:%.2fms" % [String(Dictionary(leaf).get("name", "")), float(Dictionary(leaf).get("usec", 0)) / 1000.0])
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var stats_delta := int(main.editor_compute_unit_stats_count) - before_stats
	var gpu_delta := int(main.gpu_geometry_query_submit_count) - before_gpu_submit
	var visual_delta := int(main.editor_visual_refresh_count) - before_visual
	if visual_delta != 0:
		_fail("Dragging parts to board used full visual refresh: %d" % visual_delta)
		return
	if catalog_delta != 0:
		_fail("Dragging parts to board refreshed catalog cards: %d" % catalog_delta)
		return
	if gpu_delta != 0:
		_fail("Dragging parts to board submitted GPU/battle geometry queries: %d" % gpu_delta)
		return
	var p95_ms := float(stats.get("p95_usec", 0.0)) / 1000.0
	var max_ms := float(stats.get("max_usec", 0.0)) / 1000.0
	print("TEAMEDIT_DRAG_TO_BOARD_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d stats_delta=%d visual_delta=%d hot=%s leaf=%s" % [
		p95_ms,
		max_ms,
		catalog_delta,
		stats_delta,
		visual_delta,
		String(stats.get("hot_scope", "")),
		",".join(leaf_texts),
	])
	quit(0)
