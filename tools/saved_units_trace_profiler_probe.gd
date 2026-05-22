extends SceneTree

const GameStateStoreScript = preload("res://scripts/state/game_state_store.gd")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main_scene := load("res://scripts/main.gd")
	var main = main_scene.new()
	root.add_child(main)
	await process_frame
	if main.saved_units_controller == null or main.hot_path_profiler == null:
		_fail("SavedUnits controller or profiler missing.")
		return
	main.saved_units_controller.mark_dirty("probe")
	if main.game_state_store.dirty_flags("saved_units") == 0:
		_fail("SavedUnits dirty mark did not reach GameStateStore.")
		return
	main.hot_path_profiler.scope_begin("saved_units.probe")
	main.hot_path_profiler.scope_end("saved_units.probe")
	var stats: Dictionary = main.hot_path_profiler.scope_stats()
	if not stats.has("saved_units.probe"):
		_fail("HotPathProfiler did not record saved unit scope.")
		return
	print("SAVED_UNITS_TRACE_PROFILER_PROBE ok")
	quit(0)
