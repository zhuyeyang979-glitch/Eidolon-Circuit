extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main) -> void:
	for _i in range(140):
		if String(main.game_state) != MainScene.STATE_LOADING:
			return
		main.tick_loading_tasks(0.016, 6000)
	_fail("TeamEdit loading did not complete.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	main._show_editor()
	_drain_loading(main)
	if String(main.game_state) != MainScene.STATE_EDITOR:
		return
	if main.editor_catalog_entries_cache.is_empty():
		_fail("TeamEdit preload did not warm catalog entries cache.")
		return
	if String(main.editor_current_stats_cache_key) == "":
		_fail("TeamEdit preload did not warm dashboard stats cache.")
		return
	if int(main.editor_visual_refresh_count) <= 0:
		_fail("TeamEdit preload did not touch board visual cache.")
		return
	print("TEAMEDIT_PRELOAD_CACHE_PROBE ok catalog_cache=%d stats_key=%s visual=%d" % [
		main.editor_catalog_entries_cache.size(),
		String(main.editor_current_stats_cache_key),
		int(main.editor_visual_refresh_count),
	])
	quit(0)
