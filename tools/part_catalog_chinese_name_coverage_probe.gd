extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartZhNames := preload("res://scripts/data/part_zh_names.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _has_cjk(value: String) -> bool:
	for i in range(value.length()):
		if value.unicode_at(i) >= 0x2e80:
			return true
	return false


func _assert_zh_name(english_name: String, zh_name: String, label: String) -> void:
	if english_name.strip_edges() == "":
		_fail("%s has an empty English catalog name." % label)
	if zh_name.strip_edges() == "":
		_fail("%s has no Chinese display name for %s." % [label, english_name])
	if not _has_cjk(zh_name):
		_fail("%s Chinese display name has no CJK text for %s: %s" % [label, english_name, zh_name])
	if zh_name.find("/") >= 0:
		_fail("%s Chinese display name should be normalized, got %s for %s." % [label, zh_name, english_name])
	if zh_name == english_name and not _has_cjk(english_name):
		_fail("%s fell back to the English name: %s." % [label, english_name])


func _all_filter_options(main, group_key: String) -> Array:
	var options: Array = []
	var seen := {}
	for weapon_group in ["all", "melee", "gun"]:
		main.editor_weapon_filter_group = weapon_group
		for raw_option in main._part_filter_options_for_group(group_key):
			if not (raw_option is Dictionary):
				continue
			var option: Dictionary = Dictionary(raw_option).duplicate(true)
			var key := "|".join([
				String(option.get("key", "")),
				String(option.get("weapon_group", "")),
				String(option.get("weapon_subtype", "")),
			])
			if seen.has(key):
				continue
			seen[key] = true
			options.append(option)
	return options


func _collect_visible_names(main) -> Dictionary:
	var names := {}
	for role_i in range(MainScene.ROLE_ORDER.size()):
		var role_key := String(MainScene.ROLE_ORDER[role_i])
		main.editor_role_index = role_i
		for raw_group in MainScene.EDITOR_PART_GROUP_ORDER:
			var group_key := String(raw_group)
			main.editor_part_group_mode = group_key
			for raw_option in _all_filter_options(main, group_key):
				var option: Dictionary = raw_option
				main.editor_part_filter_mode = String(option.get("key", ""))
				main.editor_weapon_filter_group = String(option.get("weapon_group", "all"))
				main.editor_weapon_filter_subtype = String(option.get("weapon_subtype", "all"))
				for raw_slot in main._slot_keys_from_filter_option(option):
					var slot_key := String(raw_slot)
					for raw_entry in main._editor_catalog_entries(role_key, slot_key):
						if not (raw_entry is Dictionary):
							continue
						var entry: Dictionary = raw_entry
						var part: Dictionary = entry.get("part", {}) if entry.get("part", {}) is Dictionary else {}
						var entry_slot := String(entry.get("slot", slot_key))
						if part.is_empty() or main._part_is_catalog_frozen(entry_slot, part):
							continue
						var name := String(part.get("name", "")).strip_edges()
						if name != "":
							names[name] = {
								"role": role_key,
								"slot": entry_slot,
								"part": part,
							}
	return names


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	main.ui_language = MainScene.UI_LANGUAGE_ZH
	var visible_names := _collect_visible_names(main)
	if visible_names.is_empty():
		_fail("No visible catalog parts were collected.")
	for english_name in visible_names.keys():
		var info: Dictionary = visible_names[english_name]
		var part: Dictionary = info.get("part", {})
		var zh_name := main._part_display_name(part)
		_assert_zh_name(String(english_name), zh_name, "%s/%s" % [String(info.get("role", "")), String(info.get("slot", ""))])
		if String(part.get("zh_name", "")).strip_edges() == "" and PartZhNames.zh_name_for(String(english_name)).strip_edges() == "":
			_fail("Visible catalog part is not covered by PartZhNames: %s." % String(english_name))
		var short_name := main._short_part_display_name(part)
		_assert_zh_name(String(english_name), short_name, "short display")
		if short_name.length() > 12:
			_fail("Short Chinese catalog name exceeds UI cap: %s -> %s" % [String(english_name), short_name])
	var sample_index := main._component_index_by_exact_name("hero", "muscle", "LIGHT RIFLE MUSCLE")
	if sample_index < 0:
		_fail("Missing LIGHT RIFLE MUSCLE sample.")
	var sample_part := main._selected_component("hero", "muscle", sample_index)
	if main._part_display_name(sample_part) != "轻型来复枪":
		_fail("Expected LIGHT RIFLE MUSCLE display name to be stable, got %s." % main._part_display_name(sample_part))
	var title := main._catalog_card_title("muscle", sample_part, sample_index, false)
	if title.find("轻型来复枪") < 0:
		_fail("Catalog card title did not use Chinese part name: %s" % title)
	var hover_title := "%02d %s" % [sample_index + 1, main._part_display_name(sample_part)]
	if hover_title.find("LIGHT RIFLE") >= 0:
		_fail("Hover title leaked English catalog name: %s" % hover_title)
	print("PART_CATALOG_CHINESE_NAME_COVERAGE_PROBE ok visible=%d" % visible_names.size())
	quit()
