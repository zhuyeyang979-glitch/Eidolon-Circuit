extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_entry_for_filter(main, filter_key: String) -> Dictionary:
	main.editor_part_group_mode = "terminal_weapon"
	main.editor_part_filter_mode = filter_key
	var entries: Array = main._editor_catalog_raw_entries("hero", "muscle")
	if entries.is_empty():
		return {}
	return Dictionary(entries[0])


func _assert_path(main, filter_key: String, expected_zh: String, expected_en: String) -> void:
	var entry := _first_entry_for_filter(main, filter_key)
	if entry.is_empty():
		_fail("No entry for filter %s." % filter_key)
	var part: Dictionary = entry.get("part", {})
	var zh_path: String = main._terminal_weapon_category_path(part, "muscle", true)
	var en_path: String = main._terminal_weapon_category_path(part, "muscle", false)
	if not zh_path.contains(expected_zh):
		_fail("Chinese category path '%s' did not contain '%s'." % [zh_path, expected_zh])
	if not en_path.contains(expected_en):
		_fail("English category path '%s' did not contain '%s'." % [en_path, expected_en])
	var current_stats := {"cost": 0, "mass": 0, "required_power": 0}
	var preview_stats := {"cost": 0, "mass": 0, "required_power": 0}
	main.ui_language = "zh"
	var zh_lines: Array = main._hover_card_detail_lines("muscle", part, current_stats, preview_stats)
	var found_zh := false
	for line in zh_lines:
		if String(line).contains("分类：") and String(line).contains(expected_zh):
			found_zh = true
			break
	if not found_zh:
		_fail("Chinese hover detail did not include category path for %s." % filter_key)
	main.ui_language = "en"
	var en_lines: Array = main._hover_card_detail_lines("muscle", part, current_stats, preview_stats)
	var found_en := false
	for line in en_lines:
		if String(line).contains("Category:") and String(line).contains(expected_en):
			found_en = true
			break
	if not found_en:
		_fail("English hover detail did not include category path for %s." % filter_key)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	_assert_path(main, "weapon_gauntlet", "武器 > 近战 > 钝击 > 拳套", "Weapon > Melee > Blunt > Gauntlet")
	_assert_path(main, "weapon_rapier", "武器 > 近战 > 戳刺 > 细剑", "Weapon > Melee > Pierce > Rapier")
	_assert_path(main, "gun_rifle", "武器 > 远程 > 来复枪", "Weapon > Ranged > Rifle")
	print("WEAPON_SUBCATEGORY_HOVER_PROBE ok")
	quit()
