extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _drain_loading(main, max_ticks: int = 160) -> void:
	for _i in range(max_ticks):
		if String(main.game_state) != MainScene.STATE_LOADING:
			return
		main.tick_loading_tasks(0.016, main.loading_task_budget_usec)
	_fail("TeamEdit deep loading did not complete.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	main._show_editor()
	_drain_loading(main)
	if String(main.game_state) != MainScene.STATE_EDITOR:
		_fail("TeamEdit deep loading did not enter editor.")
		return
	if int(main.loading_last_max_duration_sec) != 10:
		_fail("TeamEdit page loading max budget should be 10 seconds.")
		return
	if int(main.post_loading_watch_remaining) != MainScene.POST_LOADING_FIRST_INTERACTION_WINDOW:
		_fail("TeamEdit did not arm first-interaction miss window.")
		return
	if main.editor_catalog_entries_cache.is_empty():
		_fail("TeamEdit preload did not warm catalog entries.")
		return
	if String(main.editor_current_stats_cache_key) == "":
		_fail("TeamEdit preload did not warm dashboard stats.")
		return
	if int(main.editor_torso_detail_refresh_count) <= 0:
		_fail("TeamEdit preload did not warm torso detail path.")
		return
	if main.editor_torso_detail_template_cache.is_empty():
		_fail("TeamEdit preload did not warm torso detail templates.")
		return
	var baseline_miss := int(main.post_loading_miss_count)
	main._record_post_loading_interaction("probe:first_teamedit")
	if int(main.post_loading_miss_count) != baseline_miss:
		_fail("First TeamEdit interaction recorded a post-loading miss: %s" % str(main.post_loading_miss_log))
		return
	print("TEAMEDIT_PAGE_DEEP_PRELOAD_PROBE ok catalog=%d visual=%d torso=%d" % [
		main.editor_catalog_entries_cache.size(),
		int(main.editor_visual_refresh_count),
		int(main.editor_torso_detail_refresh_count),
	])
	quit(0)
