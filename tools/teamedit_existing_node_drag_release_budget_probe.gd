extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_index(main, slot_key: String) -> int:
	var catalog: Array = main._catalog_for("hero", slot_key)
	return 0 if not catalog.is_empty() else -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._start_blank_topology()
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	var slot_key := "limb_muscle"
	var part_index := _first_index(main, slot_key)
	if part_index < 0:
		slot_key = "muscle"
		part_index = _first_index(main, slot_key)
	if part_index < 0:
		_fail("No topology part available.")
		return
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, part_index)
	var node_index := main._add_topology_node_at(Vector2(260, 220))
	if node_index < 0:
		_fail("Could not create node.")
		return
	main._refresh_editor_visual_views_fast_drag([node_index])
	main.editor_dirty_flags = 0
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_stats := int(main.editor_compute_unit_stats_count)
	var before_gpu := int(main.gpu_geometry_query_submit_count)
	main.hot_path_profiler.begin_interaction("teamedit.existing_node_drag_release")
	for i in range(10):
		main.hot_path_profiler.begin_frame()
		main.editor_dragging_node_index = node_index
		main._move_custom_node_to(unit_bp, node_index, Vector2(280 + i * 5, 240 + i * 2))
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.begin_frame()
	main.editor_dragging_node_index = node_index
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(330, 260)
	main._handle_editor_board_input(release)
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.existing_node_drag_release")
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var stats_delta := int(main.editor_compute_unit_stats_count) - before_stats
	var gpu_delta := int(main.gpu_geometry_query_submit_count) - before_gpu
	if catalog_delta != 0:
		_fail("Existing node drag/release refreshed catalog cards: %d" % catalog_delta)
		return
	if gpu_delta != 0:
		_fail("Existing node drag/release submitted GPU geometry queries: %d" % gpu_delta)
		return
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.existing_node_drag_release")
	print("TEAMEDIT_EXISTING_NODE_DRAG_RELEASE_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d stats_delta=%d socket_updates=%d socket_hits=%d" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_delta,
		stats_delta,
		int(main.editor_socket_candidate_update_count),
		int(main.editor_socket_candidate_cache_hit_count),
	])
	quit(0)
