extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, max_ticks: int = 240) -> void:
	for _i in range(max_ticks):
		if String(main.game_state) != MainScene.STATE_LOADING:
			return
		main.tick_loading_tasks(0.016, 6000)
	_fail("Loading did not complete within tick budget.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	if String(main.game_state) != MainScene.STATE_LOADING:
		_fail("Startup/menu transition did not enter Loading.")
		return
	if main.loading_layer == null or not main.loading_layer.visible:
		_fail("Loading layer is not visible during startup transition.")
		return
	_drain_loading(main)
	if String(main.game_state) != MainScene.STATE_MENU:
		_fail("Startup loading did not finish on menu.")
		return
	if int(main.loading_completed_count) <= 0:
		_fail("Loading completion counter did not advance.")
		return
	print("STARTUP_LOADING_STAGE_PROBE ok transitions=%d completed=%d" % [int(main.loading_transition_count), int(main.loading_completed_count)])
	quit(0)
