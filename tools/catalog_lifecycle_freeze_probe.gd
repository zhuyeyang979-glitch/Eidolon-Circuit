extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entry_names(entries: Array) -> Array:
	var names: Array = []
	for raw in entries:
		if raw is Dictionary:
			var entry: Dictionary = raw
			var part: Dictionary = entry.get("part", {})
			names.append(String(part.get("name", "")))
	return names


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var old_laser_index: int = main._component_index_by_exact_name("hero", "muscle", "LASER EMITTER GUN")
	if old_laser_index < 0:
		_fail("Expected old LASER EMITTER GUN to remain in raw catalog for future development.")
	var old_laser: Dictionary = main._selected_component("hero", "muscle", old_laser_index)
	if not main._part_is_catalog_frozen("muscle", old_laser):
		_fail("Old LASER EMITTER GUN should be frozen.")
	var standard_index: int = main._component_index_by_exact_name("hero", "muscle", MainScene.STANDARD_LASER_NAME)
	if standard_index < 0:
		_fail("Missing standard laser.")
	var standard: Dictionary = main._selected_component("hero", "muscle", standard_index)
	if main._part_is_catalog_frozen("muscle", standard):
		_fail("Standard laser should remain live.")
	main._show_editor()
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = "all"
	var entries: Array = main._editor_catalog_entries("hero", "muscle")
	var names := _entry_names(entries)
	if names.has("LASER EMITTER GUN"):
		_fail("Frozen old laser leaked into player purchase entries.")
	if not names.has(MainScene.STANDARD_LASER_NAME):
		_fail("Live standard laser missing from player purchase entries.")
	print("CATALOG_LIFECYCLE_FREEZE_PROBE ok entries=%d old_laser_index=%d" % [entries.size(), old_laser_index])
	quit()
