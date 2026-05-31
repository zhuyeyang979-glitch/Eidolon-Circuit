extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _option_keys(options: Array) -> Array:
	var keys: Array = []
	for option in options:
		if option is Dictionary:
			keys.append(String(Dictionary(option).get("key", "")))
	return keys


func _first_entry_for_filter(main, group_key: String, filter_key: String, slot_key: String) -> Dictionary:
	main.editor_part_group_mode = group_key
	main.editor_part_filter_mode = filter_key
	main.editor_catalog_page = 0
	var entries: Array = main._editor_catalog_entries("hero", slot_key)
	if entries.is_empty():
		return {}
	return entries[0]


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var expected := ["torso", "limb", "terminal_weapon", "barrier_panel", "software_muscle", "software"]
	if MainScene.EDITOR_PART_GROUP_ORDER != expected:
		_fail("top-level groups must be %s, got %s" % [str(expected), str(MainScene.EDITOR_PART_GROUP_ORDER)])
	var required := {
		"torso": ["connector_torso", "connector_brain"],
		"limb": ["connector_limb"],
		"terminal_weapon": ["terminal", "terminal_ranged", "terminal_melee"],
		"barrier_panel": ["barrier_muscle"],
		"software_muscle": ["engine", "booster", "cooling", "ammo", "shield_payload"],
		"software": ["soul", "code", "ether", "module"],
	}
	for group_key in required.keys():
		var keys := _option_keys(main._part_filter_options_for_group(String(group_key)))
		for filter_key in Array(required[group_key]):
			if not keys.has(String(filter_key)):
				_fail("%s missing filter %s in %s" % [String(group_key), String(filter_key), str(keys)])
	var torso_entry := _first_entry_for_filter(main, "torso", "connector_torso", "muscle")
	if torso_entry.is_empty() or not main._component_is_torso(Dictionary(torso_entry.get("part", {}))):
		_fail("torso group must surface torso components first.")
	var limb_entry := _first_entry_for_filter(main, "limb", "connector_limb", "limb_muscle")
	if limb_entry.is_empty() or String(limb_entry.get("slot", "")) != "limb_muscle":
		_fail("limb group must surface limb_muscle entries.")
	var weapon_entry := _first_entry_for_filter(main, "terminal_weapon", "terminal", "muscle")
	if weapon_entry.is_empty() or not main._part_counts_as_terminal_weapon(Dictionary(weapon_entry.get("part", {})), "muscle"):
		_fail("terminal weapon group must surface terminal weapons.")
	print("PART_LIBRARY_TOPLEVEL_PROBE ok groups=%s" % str(MainScene.EDITOR_PART_GROUP_ORDER))
	quit()
