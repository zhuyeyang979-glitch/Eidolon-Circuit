extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	if source.is_empty():
		_fail("Unable to read main.gd.")
		return
	var required := [
		"scripts/state/game_state_store.gd",
		"scripts/state/dirty_graph.gd",
		"scripts/state/derived_state_cache.gd",
		"scripts/perf/hot_path_profiler.gd",
		"scripts/services/gpu_geometry_service.gd",
		"scripts/controllers/team_edit_controller.gd",
		"scripts/controllers/battle_controller.gd",
		"func _initialize_hot_path_state_layer",
	]
	for token in required:
		if not source.contains(token):
			_fail("main.gd is missing controller/state adapter token: %s" % token)
			return
	if source.contains("team_edit_controller = null") or source.contains("battle_controller = null"):
		_fail("Controller adapters are explicitly disabled.")
		return
	print("MAIN_CONTROLLER_BOUNDARY_PROBE ok")
	quit(0)
