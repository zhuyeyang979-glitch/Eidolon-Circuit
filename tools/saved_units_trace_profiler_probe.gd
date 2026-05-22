extends SceneTree

const MainScene := preload("res://scripts/main.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.saved_units_controller == null or main.hot_path_profiler == null:
		_fail("SavedUnits controller or profiler missing.")
		return
	main._show_saved_units_library("menu")
	main.saved_units_controller.mark_dirty("probe")
	if main.game_state_store.dirty_flags("saved_units") == 0:
		_fail("SavedUnits dirty mark did not reach GameStateStore.")
		return
	main.hot_path_profiler.begin_interaction("saved_units.page")
	for i in range(18):
		main.hot_path_profiler.begin_frame()
		main.hot_path_profiler.scope_begin("saved_units.page_update")
		main._update_saved_units_ui()
		main.hot_path_profiler.scope_end("saved_units.page_update")
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("saved_units.page")
	main.hot_path_profiler.begin_interaction("saved_units.hover")
	for i in range(24):
		main.hot_path_profiler.begin_frame()
		main.hot_path_profiler.scope_begin("saved_units.hover_update")
		main._update_saved_units_hover(Vector2(86.0, 168.0 + float(i % 6) * 72.0))
		main.hot_path_profiler.scope_end("saved_units.hover_update")
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("saved_units.hover")
	var page_stats: Dictionary = main.hot_path_profiler.interaction_stats("saved_units.page")
	var hover_stats: Dictionary = main.hot_path_profiler.interaction_stats("saved_units.hover")
	if int(page_stats.get("count", 0)) <= 0 or int(hover_stats.get("count", 0)) <= 0:
		_fail("SavedUnits profiler did not record interaction samples.")
		return
	print("SAVED_UNITS_TRACE_PROFILER_PROBE ok page_p95=%.2fms hover_p95=%.2fms hot=%s" % [
		float(page_stats.get("p95_usec", 0)) / 1000.0,
		float(hover_stats.get("p95_usec", 0)) / 1000.0,
		String(hover_stats.get("hot_scope", "")),
	])
	quit(0)
