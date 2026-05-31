extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._start_blank_topology()
	main._update_editor_ui(true)
	main.flush_editor_dirty(0)
	var catalog: Array = main._catalog_for("hero", "limb_muscle")
	if catalog.is_empty():
		catalog = main._catalog_for("hero", "muscle")
	if catalog.is_empty():
		_fail("No topology part available.")
		return
	var slot_key := "limb_muscle" if not main._catalog_for("hero", "limb_muscle").is_empty() else "muscle"
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._set_pending_canvas_part(unit_bp, slot_key, 0)
	var node_index := main._add_topology_node_at(Vector2(300, 260))
	if node_index < 0:
		_fail("Could not create pose node.")
		return
	main._refresh_editor_visual_views_fast_drag([node_index])
	main.editor_dirty_flags = 0
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_gpu := int(main.gpu_geometry_query_submit_count)
	main.editor_pose_dragging = true
	main.editor_pose_root_node = node_index
	main.editor_pose_downstream_nodes = [node_index]
	main.editor_pose_drag_original_positions = [{"index": node_index, "local_angle": 0.0}]
	main.hot_path_profiler.begin_interaction("teamedit.pose_commit")
	main.hot_path_profiler.begin_frame()
	main._finish_editor_pose_drag(unit_bp)
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.pose_commit")
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var gpu_delta := int(main.gpu_geometry_query_submit_count) - before_gpu
	if catalog_delta != 0:
		_fail("Pose commit refreshed catalog cards: %d" % catalog_delta)
		return
	if gpu_delta != 0:
		_fail("Pose commit submitted GPU geometry queries: %d" % gpu_delta)
		return
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.pose_commit")
	print("TEAMEDIT_POSE_COMMIT_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d gpu_delta=%d" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_delta,
		gpu_delta,
	])
	quit(0)
