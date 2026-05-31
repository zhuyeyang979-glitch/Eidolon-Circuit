extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _settle_loading(main) -> void:
	for _i in range(24):
		if main.game_state != main.STATE_LOADING:
			return
		main.tick_loading_tasks(0.1, 1000000)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MainScene.new()
	root.add_child(main)
	_settle_loading(main)
	main.loading_auto_transitions_enabled = false
	var first_max := 0.0
	var last_max := 0.0
	for cycle in range(5):
		main.performance_frame_samples.clear()
		main._show_editor(true)
		main._process(0.016)
		await process_frame
		main._show_saved_units_library("", "editor", false, true)
		main._process(0.016)
		await process_frame
		main._show_settings(true)
		main._process(0.016)
		await process_frame
		main._show_menu(true)
		main._process(0.016)
		await process_frame
		var snapshot: Dictionary = main._ui_lifecycle_snapshot()
		if cycle == 0:
			first_max = float(snapshot.get("frame_max_ms", 0.0))
		last_max = float(snapshot.get("frame_max_ms", 0.0))
	if last_max > maxf(40.0, first_max + 18.0):
		_fail("Frame max grew after page transitions: first=%.2f last=%.2f" % [first_max, last_max])
	var after: Dictionary = main._ui_lifecycle_snapshot()
	if int(after.get("loading_idle_tasks", 0)) > 1:
		_fail("Idle loading tasks accumulated during frame regression probe: %s" % str(after))
	print("PAGE_TRANSITION_FRAME_TIME_REGRESSION_PROBE ok first=%.2fms last=%.2fms" % [first_max, last_max])
	quit(0)
