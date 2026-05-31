extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	for i in range(40):
		main.saved_unit_filtered_cache["filter_%d" % i] = []
	for i in range(210):
		main.saved_unit_stats_cache["stats_%d" % i] = {}
		main.saved_unit_illegal_cache["illegal_%d" % i] = ""
	main.saved_unit_hovered_path = "dummy"
	main.saved_unit_detail_path = "dummy"
	main.saved_unit_focus_path = "dummy"
	main.saved_unit_deferred_focus_path = "dummy"
	main.saved_unit_pending_delete_paths = ["dummy"]
	main._cleanup_saved_units_page_runtime()
	var snapshot: Dictionary = main._ui_lifecycle_snapshot()
	if not main.saved_unit_filtered_cache.is_empty():
		_fail("Saved-unit filtered cache should be page-local and cleared.")
	if not main.saved_unit_stats_cache.is_empty() or not main.saved_unit_illegal_cache.is_empty():
		_fail("Saved-unit stat caches should be page-local and cleared: %s" % str(snapshot))
	if main.saved_unit_hovered_path != "" or main.saved_unit_detail_path != "" or main.saved_unit_focus_path != "" or main.saved_unit_deferred_focus_path != "" or not main.saved_unit_pending_delete_paths.is_empty():
		_fail("Saved-unit transient state survived cleanup.")
	if not bool(main.saved_unit_library_cache_dirty):
		_fail("Saved-unit library should be marked dirty so re-entry checks disk like a fresh page entry.")
	print("SAVED_UNITS_PREVIEW_CACHE_CAP_PROBE ok stats=%d illegal=%d" % [
		main.saved_unit_stats_cache.size(),
		main.saved_unit_illegal_cache.size(),
	])
	quit(0)
