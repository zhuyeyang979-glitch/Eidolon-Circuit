extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _check_group(main, group_key: String) -> int:
	main.editor_part_group_mode = group_key
	var total := 0
	for option in main._part_filter_options_for_group(group_key):
		if not (option is Dictionary):
			continue
		main.editor_part_filter_mode = String(Dictionary(option).get("key", "all"))
		var slot_keys: Array = main._editor_catalog_slots_for_active_filter("muscle")
		for raw_slot in slot_keys:
			var slot_key := String(raw_slot)
			var entries: Array = main._editor_catalog_entries("hero", slot_key)
			for raw_entry in entries:
				if not (raw_entry is Dictionary):
					continue
				var entry: Dictionary = raw_entry
				var part: Dictionary = entry.get("part", {})
				var entry_slot := String(entry.get("slot", slot_key))
				if main._part_is_catalog_frozen(entry_slot, part):
					_fail("Frozen part leaked into purchase entries: %s/%s filter=%s" % [entry_slot, String(part.get("name", "")), main.editor_part_filter_mode])
				total += 1
	return total


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var total := 0
	for group_key in MainScene.EDITOR_PART_GROUP_ORDER:
		total += _check_group(main, String(group_key))
	if total <= 0:
		_fail("No live purchase entries were visible.")
	var old_laser_index: int = main._component_index_by_exact_name("hero", "muscle", "LASER EMITTER GUN")
	var old_laser: Dictionary = main._selected_component("hero", "muscle", old_laser_index)
	if old_laser.is_empty() or not main._part_is_catalog_frozen("muscle", old_laser):
		_fail("Frozen index-read compatibility failed for old laser.")
	print("CATALOG_LIVE_PURCHASE_PROBE ok entries=%d" % total)
	quit()
