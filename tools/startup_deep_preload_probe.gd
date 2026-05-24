extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, max_ticks: int = 260) -> void:
	for _i in range(max_ticks):
		if String(main.game_state) != MainScene.STATE_LOADING:
			return
		main.tick_loading_tasks(0.016, main.loading_task_budget_usec)
	_fail("Startup deep loading did not complete.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	if String(main.game_state) != MainScene.STATE_LOADING:
		_fail("Startup deep probe expected _ready() to enter loading.")
		return
	_drain_loading(main)
	if String(main.game_state) != MainScene.STATE_MENU:
		_fail("Startup deep loading did not enter menu.")
		return
	if int(main.loading_last_max_duration_sec) != 20:
		_fail("Startup loading max budget should be 20 seconds.")
		return
	if main.editor_catalog_entries_cache.is_empty():
		_fail("Startup preload did not warm catalog index cache.")
		return
	if bool(main.saved_unit_library_cache_dirty):
		_fail("Startup preload did not warm saved-unit summary cache.")
		return
	print("STARTUP_DEEP_PRELOAD_PROBE ok catalog_cache=%d saved=%d idle=%d" % [
		main.editor_catalog_entries_cache.size(),
		main.saved_unit_library_cache.size(),
		main.loading_idle_tasks.size(),
	])
	quit(0)
