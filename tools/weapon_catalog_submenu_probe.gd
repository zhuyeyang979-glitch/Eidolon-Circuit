extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _filter_index(main, key: String) -> int:
	var options: Array = main._part_filter_options_for_group(main.editor_part_group_mode)
	for i in range(options.size()):
		if options[i] is Dictionary and String(Dictionary(options[i]).get("key", "")) == key:
			return i
	return -1


func _entries(main) -> Array:
	return main._editor_catalog_entries(main.ROLE_ORDER[main.editor_role_index], "muscle")


func _assert_all(main, entries: Array, group: String, subtype: String) -> void:
	if entries.is_empty():
		_fail("Filter %s/%s returned no entries." % [group, subtype])
		return
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		var part: Dictionary = entry.get("part", {})
		var terminal_kind: String = main._terminal_weapon_kind_for_part(part, "muscle")
		if group == "melee" and terminal_kind != "melee":
			_fail("Melee submenu included non-melee part: %s" % String(part.get("name", "")))
			return
		if group == "gun" and terminal_kind != "ranged":
			_fail("Gun submenu included non-ranged part: %s" % String(part.get("name", "")))
			return
		if subtype == "blade" and not main._component_is_blade_weapon(part):
			_fail("Blade submenu included wrong part: %s" % String(part.get("name", "")))
			return
		if subtype == "sprayer" and main._gun_family_for_part(part) != "sprayer":
			_fail("Sprayer submenu included wrong gun: %s" % String(part.get("name", "")))
			return


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main._select_editor_part_group("terminal_weapon")
	var base_options: Array = main._part_filter_options_for_group("terminal_weapon")
	if base_options.size() != 3:
		_fail("Weapon base submenu should expose all/melee/gun only, got %d." % base_options.size())
		return
	var melee_index := _filter_index(main, "weapon_melee")
	if melee_index < 0:
		_fail("Missing melee weapon submenu button.")
		return
	main._select_editor_part_filter(melee_index)
	if main.editor_weapon_filter_group != "melee":
		_fail("Melee submenu did not set weapon_filter_group.")
		return
	var melee_options: Array = main._part_filter_options_for_group("terminal_weapon")
	if _filter_index(main, "weapon_blade") < 0 or _filter_index(main, "weapon_blunt") < 0 or _filter_index(main, "weapon_pierce") < 0:
		_fail("Melee submenu did not expose blade/blunt/pierce filters.")
		return
	_assert_all(main, _entries(main), "melee", "all")
	var blade_index := _filter_index(main, "weapon_blade")
	main._select_editor_part_filter(blade_index)
	_assert_all(main, _entries(main), "melee", "blade")
	main._select_editor_part_group("terminal_weapon")
	var gun_index := _filter_index(main, "weapon_gun")
	if gun_index < 0:
		_fail("Missing gun weapon submenu button.")
		return
	main._select_editor_part_filter(gun_index)
	if main.editor_weapon_filter_group != "gun":
		_fail("Gun submenu did not set weapon_filter_group.")
		return
	if _filter_index(main, "gun_sniper") < 0 or _filter_index(main, "gun_sprayer") < 0 or _filter_index(main, "gun_web") < 0:
		_fail("Gun submenu did not expose expected gun subtype filters.")
		return
	_assert_all(main, _entries(main), "gun", "all")
	var sprayer_index := _filter_index(main, "gun_sprayer")
	if sprayer_index >= 0:
		main._select_editor_part_filter(sprayer_index)
		var sprayer_entries := _entries(main)
		if not sprayer_entries.is_empty():
			_assert_all(main, sprayer_entries, "gun", "sprayer")
	print("WEAPON_CATALOG_SUBMENU_PROBE ok melee_options=%d gun_options=%d" % [melee_options.size(), main._part_filter_options_for_group("terminal_weapon").size()])
	quit(0)
