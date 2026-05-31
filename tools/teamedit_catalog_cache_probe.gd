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
	main.editor_panel_mode = "parts"
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	main.editor_slot_index = MainScene.BUILD_SLOTS.find("muscle")
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = "terminal_melee"
	main.editor_catalog_sort_key = "cost"
	main.editor_catalog_sort_ascending = true
	main._invalidate_editor_catalog_cache()
	main.editor_catalog_cache_hit_count = 0
	main.editor_catalog_cache_miss_count = 0
	var first: Array = main._editor_catalog_entries("hero", "muscle")
	var miss_after_first := int(main.editor_catalog_cache_miss_count)
	var second: Array = main._editor_catalog_entries("hero", "muscle")
	var hit_after_second := int(main.editor_catalog_cache_hit_count)
	if first.is_empty():
		_fail("Catalog cache probe needs at least one melee terminal entry.")
	if second.size() != first.size():
		_fail("Cached catalog entry count changed: %d vs %d" % [second.size(), first.size()])
	if miss_after_first <= 0:
		_fail("First catalog query did not populate cache.")
	if hit_after_second <= 0:
		_fail("Second catalog query did not hit cache.")
	print("TEAMEDIT_CATALOG_CACHE_PROBE ok entries=%d miss=%d hit=%d" % [first.size(), miss_after_first, hit_after_second])
	quit()
