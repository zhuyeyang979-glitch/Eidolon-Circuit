extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.editor_panel_mode = "load"
	main.editor_load_entry_stats_cache.clear()
	var entries: Array = main._editor_load_entries()
	if entries.is_empty():
		_fail("No load entries available for stats cache probe.")
	var entry: Dictionary = {}
	for raw_entry in entries:
		if raw_entry is Dictionary and not bool(Dictionary(raw_entry).get("empty", false)):
			entry = Dictionary(raw_entry)
			break
	if entry.is_empty():
		entry = {"role": "hero", "index": 0, "blueprint": main._editor_current_blueprint(), "unit_library": true}
	main.editor_compute_unit_stats_count = 0
	var first: Dictionary = main._editor_load_entry_stats(main._editor_player(), "hero", entry)
	var second: Dictionary = main._editor_load_entry_stats(main._editor_player(), "hero", entry)
	if first.is_empty() or second.is_empty():
		_fail("Load entry stats cache returned empty stats.")
	if int(main.editor_compute_unit_stats_count) != 1:
		_fail("Load entry stats recomputed instead of using cache: %d" % int(main.editor_compute_unit_stats_count))
	print("EDITOR_LOAD_CARD_STATS_CACHE_PROBE ok compute=%d cache=%d" % [int(main.editor_compute_unit_stats_count), main.editor_load_entry_stats_cache.size()])
	quit()
