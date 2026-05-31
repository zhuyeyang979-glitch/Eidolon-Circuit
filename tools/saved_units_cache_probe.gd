extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _reset_counters(main: Node) -> void:
	main.saved_unit_cache_disk_scan_count = 0
	main.saved_unit_cache_json_load_count = 0
	main.saved_unit_cache_stats_compute_count = 0
	main.saved_unit_cache_illegal_compute_count = 0


func _init() -> void:
	var main := MainScene.new()
	root.add_child(main)
	main._ready()
	main._invalidate_saved_unit_library_cache()
	main._show_saved_units_library()
	_reset_counters(main)
	for _i in range(5):
		main._update_saved_units_ui()
	if int(main.saved_unit_cache_disk_scan_count) != 0:
		_fail("Saved unit UI refresh should not rescan disk when cache is warm.")
	if int(main.saved_unit_cache_json_load_count) != 0:
		_fail("Saved unit UI refresh should not reload JSON when cache is warm.")
	if int(main.saved_unit_cache_stats_compute_count) != 0:
		_fail("Saved unit UI refresh should not recompute visible stats when cache is warm.")
	if int(main.saved_unit_cache_illegal_compute_count) != 0:
		_fail("Saved unit UI refresh should not recompute legality when cache is warm.")
	print("SAVED_UNITS_CACHE_PROBE ok entries=%d" % main.saved_unit_library_cache.size())
	quit()
