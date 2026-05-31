extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MIN_FPS := 72
const P95_FRAME_MS_LIMIT := 13.8
const MAX_FRAME_MS_LIMIT := 16.6


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._apply_performance_profile("compat_60", false)
	if Engine.max_fps < MIN_FPS:
		_fail("Compat profile must cap at least 72fps; got Engine.max_fps=%d." % Engine.max_fps)
		return
	if int(main._runtime_quality_value("fps_cap", 0)) < MIN_FPS:
		_fail("Runtime quality fps_cap should be at least %d." % MIN_FPS)
		return
	main.hot_path_profiler.begin_interaction("battle.minimum_72fps")
	for i in range(360):
		main.hot_path_profiler.begin_frame()
		main._tick_battle(1.0 / float(MIN_FPS))
		main.hot_path_profiler.end_frame()
	main.hot_path_profiler.end_interaction("battle.minimum_72fps")
	var stats: Dictionary = main.hot_path_profiler.interaction_stats("battle.minimum_72fps")
	var p95_ms := float(stats.get("p95_usec", 0)) / 1000.0
	var max_ms := float(stats.get("max_usec", 0)) / 1000.0
	if p95_ms > P95_FRAME_MS_LIMIT:
		_fail("72fps battle p95 frame budget exceeded: %.2fms > %.2fms." % [p95_ms, P95_FRAME_MS_LIMIT])
		return
	if max_ms > MAX_FRAME_MS_LIMIT:
		_fail("72fps battle max frame budget exceeded: %.2fms > %.2fms." % [max_ms, MAX_FRAME_MS_LIMIT])
		return
	print("BATTLE_MINIMUM_72FPS_PROBE ok fps_cap=%d p95=%.2fms max=%.2fms" % [Engine.max_fps, p95_ms, max_ms])
	quit(0)
