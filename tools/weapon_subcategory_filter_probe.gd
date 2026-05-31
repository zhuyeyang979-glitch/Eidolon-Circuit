extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entries_for_filter(main, filter_key: String) -> Array:
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = filter_key
	return main._editor_catalog_raw_entries("hero", "muscle")


func _entry_names(entries: Array) -> Array:
	var names: Array = []
	for raw_entry in entries:
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			var part: Dictionary = entry.get("part", {})
			names.append(String(part.get("name", "")))
	return names


func _assert_filter_has(main, filter_key: String, item_name: String) -> void:
	var names := _entry_names(_entries_for_filter(main, filter_key))
	if not names.has(item_name):
		_fail("%s should expose %s." % [filter_key, item_name])


func _assert_matches(main, filter_key: String) -> void:
	var entries := _entries_for_filter(main, filter_key)
	if entries.is_empty():
		return
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		var part: Dictionary = entry.get("part", {})
		var kind: String = main._terminal_weapon_kind_for_part(part, "muscle")
		match filter_key:
			"terminal_melee":
				if kind != "melee":
					_fail("%s included a non-melee entry: %s" % [filter_key, String(part.get("name", ""))])
			"terminal_ranged":
				if kind != "ranged":
					_fail("%s included a non-ranged entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_blade":
				if not main._component_is_blade_weapon(part):
					_fail("%s included a non-blade entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_blunt":
				if not main._component_is_blunt_weapon(part):
					_fail("%s included a non-blunt entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_pierce":
				if not main._component_is_pierce_weapon(part):
					_fail("%s included a non-pierce entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_scythe":
				if main._blade_weapon_family_for_part(part) != "scythe":
					_fail("%s included a non-scythe entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_katana":
				if main._blade_weapon_family_for_part(part) != "katana":
					_fail("%s included a non-katana entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_greatsword":
				if main._blade_weapon_family_for_part(part) != "greatsword":
					_fail("%s included a non-greatsword entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_gauntlet":
				if main._blunt_weapon_family_for_part(part) != "gauntlet":
					_fail("%s included a non-gauntlet entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_shield":
				if main._blunt_weapon_family_for_part(part) != "shield":
					_fail("%s included a non-shield entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_hammer":
				if main._blunt_weapon_family_for_part(part) != "hammer":
					_fail("%s included a non-hammer entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_lance":
				if main._pierce_weapon_family_for_part(part) != "lance":
					_fail("%s included a non-lance entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_rapier":
				if main._pierce_weapon_family_for_part(part) != "rapier":
					_fail("%s included a non-rapier entry: %s" % [filter_key, String(part.get("name", ""))])
			"weapon_drill":
				if main._pierce_weapon_family_for_part(part) != "drill":
					_fail("%s included a non-drill entry: %s" % [filter_key, String(part.get("name", ""))])
			"gun_sniper", "gun_rifle", "gun_laser_gun", "gun_sprayer", "gun_grenade_launcher", "gun_missile_launcher", "gun_web":
				if kind != "ranged" or not main._gun_family_matches_filter(part, filter_key):
					_fail("%s included an incompatible ranged entry: %s" % [filter_key, String(part.get("name", ""))])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var expected := [
		"terminal", "terminal_melee", "terminal_ranged",
		"weapon_blade", "weapon_blunt", "weapon_pierce",
		"weapon_scythe", "weapon_katana", "weapon_greatsword",
		"weapon_gauntlet", "weapon_shield", "weapon_hammer",
		"weapon_lance", "weapon_rapier", "weapon_drill",
		"gun_sniper", "gun_rifle", "gun_laser_gun", "gun_sprayer",
		"gun_grenade_launcher", "gun_missile_launcher", "gun_web",
	]
	var options := main._all_part_filter_options_for_group("terminal_weapon")
	var option_keys: Array = []
	for option in options:
		option_keys.append(String(Dictionary(option).get("key", "")))
	for key in expected:
		if not option_keys.has(key):
			_fail("Missing weapon filter key: %s" % key)
		_assert_matches(main, key)
	if _entries_for_filter(main, "weapon_gauntlet").is_empty():
		_fail("Gauntlet filter should expose the current blunt gauntlet gradient.")
	_assert_filter_has(main, "weapon_scythe", "SHORT CRESCENT SCYTHE")
	_assert_filter_has(main, "weapon_katana", "WAKIZASHI KATANA MUSCLE")
	_assert_filter_has(main, "weapon_greatsword", "STANDARD GREATSWORD MUSCLE")
	_assert_filter_has(main, "weapon_shield", "BUCKLER RAM SHIELD")
	_assert_filter_has(main, "weapon_hammer", "COLOSSUS ARENA MAUL")
	_assert_filter_has(main, "weapon_lance", "SHORT JOUSTING LANCE")
	_assert_filter_has(main, "weapon_rapier", "DUELING RAPIER MUSCLE")
	_assert_filter_has(main, "weapon_drill", "MICRO DRILL BIT")
	if _entries_for_filter(main, "gun_rifle").is_empty():
		_fail("Rifle filter should expose the existing rifle data.")
	print("WEAPON_SUBCATEGORY_FILTER_PROBE ok")
	quit()
