extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main_scene := load("res://scripts/main.gd")
	var main = main_scene.new()
	root.add_child(main)
	await process_frame
	if main.hot_path_profiler == null or main.game_state_store == null or main.dirty_graph == null:
		_fail("Global hot path state layer was not initialized.")
		return
	main._set_editor_perf_overlay_enabled(true)
	var text: String = main._editor_perf_overlay_text()
	if not text.contains("hotpath:") or not text.contains("state:") or not text.contains("dirty graph:") or not text.contains("derived:"):
		_fail("Perf overlay does not expose global state/hot path layers.")
		return
	print("GLOBAL_HOT_PATH_OVERLAY_PROBE ok")
	quit(0)
