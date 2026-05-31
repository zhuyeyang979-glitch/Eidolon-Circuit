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
	main.editor_panel_mode = "parts"
	main._update_editor_ui(true)
	var before_catalog := int(main.editor_catalog_card_update_count)
	var before_visual := int(main.editor_visual_refresh_count)
	var before_saved_scan := int(main.saved_unit_cache_disk_scan_count)
	main.hot_path_profiler.begin_interaction("teamedit.bottom_buttons")
	for action in ["save_canvas", "open_saved_units"]:
		main.hot_path_profiler.begin_frame()
		main._editor_action(action)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("teamedit.bottom_buttons")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("teamedit.bottom_buttons")
	var catalog_delta := int(main.editor_catalog_card_update_count) - before_catalog
	var visual_delta := int(main.editor_visual_refresh_count) - before_visual
	var saved_scan_delta := int(main.saved_unit_cache_disk_scan_count) - before_saved_scan
	if catalog_delta != 0:
		_fail("Bottom buttons refreshed catalog cards before page work: %d" % catalog_delta)
		return
	print("TEAMEDIT_BOTTOM_BUTTONS_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms catalog_delta=%d visual_delta=%d saved_scan_delta=%d hot=%s" % [
		float(stats.get("p95_usec", 0.0)) / 1000.0,
		float(stats.get("max_usec", 0.0)) / 1000.0,
		catalog_delta,
		visual_delta,
		saved_scan_delta,
		String(stats.get("hot_scope", "")),
	])
	quit(0)
