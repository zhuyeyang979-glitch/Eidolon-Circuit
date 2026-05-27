extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _snapshot_total(snapshot: Dictionary, key: String) -> int:
	return int(snapshot.get(key, 0))


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
	await process_frame
	var baseline: Dictionary = main._ui_lifecycle_snapshot()
	for _cycle in range(4):
		main._show_editor(true)
		await process_frame
		main._show_saved_units_library("", "editor", false, true)
		await process_frame
		main._show_settings(true)
		await process_frame
		main._show_scout(main.MODE_AI, true)
		await process_frame
		main._begin_battle(main.MODE_AI, true, "page_cycle_probe")
		await process_frame
		main._show_menu(true)
		await process_frame
	var after: Dictionary = main._ui_lifecycle_snapshot()
	if String(after.get("page", "")) != main.STATE_MENU:
		_fail("Page cycle did not end on menu: %s" % String(after.get("page", "")))
	if _snapshot_total(after, "battle_runtime_count") != 0:
		_fail("Battle runtime objects survived page cycle: %s" % str(after))
	if _snapshot_total(after, "loading_idle_tasks") > 1:
		_fail("Loading idle tasks accumulated after page cycle: %s" % str(after))
	var node_growth := _snapshot_total(after, "total_nodes") - _snapshot_total(baseline, "total_nodes")
	if node_growth > 96:
		_fail("Page cycle node growth too high: %d baseline=%s after=%s" % [node_growth, str(baseline), str(after)])
	if _snapshot_total(after, "preview_texture_cache") > 256 or _snapshot_total(after, "catalog_body_cache") > 256:
		_fail("Texture cache exceeded LRU cap after cycle: %s" % str(after))
	print("PAGE_CYCLE_LIFECYCLE_LEAK_PROBE ok nodes=%d growth=%d idle=%d" % [
		_snapshot_total(after, "total_nodes"),
		node_growth,
		_snapshot_total(after, "loading_idle_tasks"),
	])
	quit(0)
