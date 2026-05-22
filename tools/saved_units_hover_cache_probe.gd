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
	main._show_saved_units_library()
	var entries: Array = main._saved_unit_filtered_entries()
	if entries.is_empty():
		_fail("Saved unit hover cache probe requires at least one saved unit.")
	_reset_counters(main)
	main._hover_saved_unit_card(0)
	var first_path := String(main.saved_unit_hovered_path)
	var stats_after_first := int(main.saved_unit_cache_stats_compute_count)
	var illegal_after_first := int(main.saved_unit_cache_illegal_compute_count)
	for _i in range(8):
		main._hover_saved_unit_card(0)
	if String(main.saved_unit_hovered_path) != first_path:
		_fail("Hovering the same card should keep the same hovered path.")
	if int(main.saved_unit_cache_stats_compute_count) != stats_after_first:
		_fail("Hovering the same card should not recompute stats.")
	if int(main.saved_unit_cache_illegal_compute_count) != illegal_after_first:
		_fail("Hovering the same card should not recompute legality.")
	if entries.size() > 1:
		main._hover_saved_unit_card(1)
		if String(main.saved_unit_hovered_path) == first_path:
			_fail("Hovering a different card should update hovered path.")
	print("SAVED_UNITS_HOVER_CACHE_PROBE ok entries=%d" % entries.size())
	quit()
