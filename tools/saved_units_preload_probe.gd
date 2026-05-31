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
	_fail("Saved Units loading did not complete.")


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = true
	main._show_saved_units_library()
	_drain_loading(main)
	if String(main.game_state) != MainScene.STATE_SAVED_UNITS:
		return
	if bool(main.saved_unit_library_cache_dirty):
		_fail("Saved Units cache remained dirty after preload.")
		return
	var scans_before := int(main.saved_unit_cache_disk_scan_count)
	main._saved_unit_filtered_entries()
	var scans_after := int(main.saved_unit_cache_disk_scan_count)
	if scans_after != scans_before:
		_fail("Saved Units filtered entries triggered a synchronous disk scan after preload.")
		return
	print("SAVED_UNITS_PRELOAD_PROBE ok entries=%d scans=%d" % [main.saved_unit_library_cache.size(), scans_after])
	quit(0)
