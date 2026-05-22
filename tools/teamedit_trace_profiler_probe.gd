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
	main._update_editor_ui(true)
	main._set_editor_perf_overlay_enabled(true)
	var part := main._selected_component("hero", "muscle", 0)
	main.hot_path_profiler.begin_interaction("hover")
	for i in range(30):
		main.hot_path_profiler.begin_frame()
		main._show_editor_part_hover("muscle", 0, part)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("hover")
	main.hot_path_profiler.begin_interaction("slider")
	for i in range(20):
		main.hot_path_profiler.begin_frame()
		main._refresh_editor_dashboard_after_allocation(false)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("slider")
	main.hot_path_profiler.begin_interaction("pose")
	for i in range(20):
		main.hot_path_profiler.begin_frame()
		main.mark_editor_dirty(MainScene.EDITOR_DIRTY_BOARD, "probe_pose")
		main.flush_editor_dirty(2400)
		main._tick_editor_visuals(1.0 / 60.0)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("pose")
	var text := main._editor_perf_overlay_text()
	for required in ["update_ui", "prop write/noop", "ui full/deferred/alloc", "visible controls", "interactions"]:
		if not text.contains(required):
			_fail("TeamEdit perf overlay missing trace field: %s" % required)
			return
	var sample_before := int(main.editor_visible_control_sample_frame)
	main._editor_perf_overlay_text()
	var sample_after := int(main.editor_visible_control_sample_frame)
	if sample_after != sample_before:
		_fail("Perf overlay visible-control count resampled on consecutive calls.")
		return
	var hover_stats: Dictionary = main.hot_path_profiler.interaction_stats("hover")
	var slider_stats: Dictionary = main.hot_path_profiler.interaction_stats("slider")
	var pose_stats: Dictionary = main.hot_path_profiler.interaction_stats("pose")
	for stat_name in ["hover", "slider", "pose"]:
		var stats: Dictionary = main.hot_path_profiler.interaction_stats(stat_name)
		if int(stats.get("count", 0)) <= 0:
			_fail("Profiler did not record interaction samples for %s." % stat_name)
			return
	print("TEAMEDIT_TRACE_PROFILER_PROBE ok hover_p95=%.2fms slider_p95=%.2fms pose_p95=%.2fms hot=%s leaf=%s" % [
		float(hover_stats.get("p95_usec", 0)) / 1000.0,
		float(slider_stats.get("p95_usec", 0)) / 1000.0,
		float(pose_stats.get("p95_usec", 0)) / 1000.0,
		String(pose_stats.get("hot_scope", "")),
		_leaf_scope_text(main.hot_path_profiler, "pose"),
	])
	quit(0)


func _leaf_scope_text(profiler, interaction_name: String) -> String:
	if profiler == null or not profiler.has_method("interaction_hot_scopes"):
		return "n/a"
	var rows: Array = profiler.interaction_hot_scopes(interaction_name, 4, true)
	var parts: Array = []
	for row in rows:
		var scope_name := String(row.get("name", ""))
		if scope_name in ["teamedit.flush_dirty", "teamedit.flush.board"]:
			continue
		parts.append("%s:%.2fms" % [scope_name, float(row.get("usec", 0)) / 1000.0])
	var text := ""
	for i in range(parts.size()):
		if i > 0:
			text += ","
		text += String(parts[i])
	return text
