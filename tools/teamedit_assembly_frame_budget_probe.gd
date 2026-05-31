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
	var unit_bp: Dictionary = main._editor_current_blueprint()
	main._ensure_custom_topology(unit_bp)
	var before_catalog := int(main.editor_catalog_card_update_count)
	main.hot_path_profiler.begin_interaction("teamedit.assembly")
	main.hot_path_profiler.begin_frame()
	main._add_topology_node()
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.begin_frame()
	main._refresh_editor_visual_views({}, false)
	main._tick_editor_visuals(1.0 / 60.0)
	main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.assembly")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.assembly")
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	if catalog_delta > main.editor_catalog_buttons.size():
		_fail("Assembly operation refreshed unrelated catalog cards: %d" % catalog_delta)
		return
	print("TEAMEDIT_ASSEMBLY_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d hot=%s" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_delta,
		String(stats.get("hot_scope", "")),
	])
	quit(0)
