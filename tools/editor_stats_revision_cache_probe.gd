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
	main.editor_current_stats_cache_key = ""
	main.editor_current_stats_cache = {}
	main.editor_current_stats_cache_hit_count = 0
	main.editor_current_stats_cache_miss_count = 0
	main.editor_compute_unit_stats_count = 0
	var first: Dictionary = main._editor_current_stats()
	var second: Dictionary = main._editor_current_stats()
	if first.is_empty() or second.is_empty():
		_fail("Stats cache returned empty stats.")
	if int(main.editor_compute_unit_stats_count) != 1:
		_fail("Current stats cache recomputed instead of hitting cache: %d" % int(main.editor_compute_unit_stats_count))
	if int(main.editor_current_stats_cache_hit_count) < 1:
		_fail("Current stats cache did not record a hit.")
	print("EDITOR_STATS_REVISION_CACHE_PROBE ok compute=%d hit=%d miss=%d" % [int(main.editor_compute_unit_stats_count), int(main.editor_current_stats_cache_hit_count), int(main.editor_current_stats_cache_miss_count)])
	quit()
