extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _filter_index(main, key: String) -> int:
	var options: Array = main._part_filter_options_for_group("software")
	for i in range(options.size()):
		if options[i] is Dictionary and String(Dictionary(options[i]).get("key", "")) == key:
			return i
	return -1


func _entries(main) -> Array:
	return main._editor_catalog_entries(main.ROLE_ORDER[main.editor_role_index], "module")


func _assert_category_entries(main, filter_key: String, expected: String) -> void:
	var index := _filter_index(main, filter_key)
	if index < 0:
		_fail("Missing module filter: %s" % filter_key)
		return
	main._select_editor_part_filter(index)
	var entries := _entries(main)
	if entries.is_empty():
		_fail("Module filter %s returned no entries." % filter_key)
		return
	for raw_entry in entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			var part: Dictionary = entry.get("part", {})
			var category: String = main._module_category_for_part(part)
			if category != expected:
				_fail("Filter %s included %s category module %s." % [filter_key, category, String(part.get("name", ""))])
				return


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._select_editor_part_group("software")
	for key in ["module", "module_melee", "module_ranged", "module_other"]:
		if _filter_index(main, key) < 0:
			_fail("Software filters should expose %s." % key)
			return
	main._select_editor_part_filter(_filter_index(main, "module"))
	if _entries(main).is_empty():
		_fail("All-module filter returned no entries.")
		return
	_assert_category_entries(main, "module_melee", "melee")
	_assert_category_entries(main, "module_ranged", "ranged")
	_assert_category_entries(main, "module_other", "other")
	print("MODULE_CATALOG_FILTER_PROBE ok")
	quit(0)
