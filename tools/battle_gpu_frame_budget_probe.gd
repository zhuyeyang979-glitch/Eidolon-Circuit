extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var before_submit := int(main.gpu_geometry_query_submit_count)
	var before_sync := 0
	if main.gpu_collision_pipeline != null:
		before_sync = int(main.gpu_collision_pipeline.total_sync_wait_usec)
	main.hot_path_profiler.begin_interaction("battle.gpu_frame_budget")
	for i in range(300):
		main.hot_path_profiler.begin_frame()
		main._tick_battle(MainScene.BATTLE_FRAME_DELTA)
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("battle.gpu_frame_budget")
	var after_sync := 0
	if main.gpu_collision_pipeline != null:
		after_sync = int(main.gpu_collision_pipeline.total_sync_wait_usec)
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("battle.gpu_frame_budget")
	print("BATTLE_GPU_FRAME_BUDGET_PROBE ok p95=%.2fms max=%.2fms gpu_submit_delta=%d gpu_sync_usec=%d hot=%s" % [
		float(stats.get("p95_usec", 0)) / 1000.0,
		float(stats.get("max_usec", 0)) / 1000.0,
		int(main.gpu_geometry_query_submit_count) - before_submit,
		after_sync - before_sync,
		String(stats.get("hot_scope", "")),
	])
	quit(0)
