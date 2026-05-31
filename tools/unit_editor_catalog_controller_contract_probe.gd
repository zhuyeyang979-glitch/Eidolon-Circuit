extends SceneTree

const CONTROLLER_PATH := "res://scripts/controllers/unit_editor_catalog_controller.gd"
const MAIN_PATH := "res://scripts/main.gd"
const UnitEditorCatalogControllerScript := preload("res://scripts/controllers/unit_editor_catalog_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(CONTROLLER_PATH):
		_fail("Missing UnitEditorCatalogController script.")
	var controller_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(CONTROLLER_PATH))
	for token in [
		"class_name UnitEditorCatalogController",
		"raw_cache_key",
		"entries_cache_key",
		"page_selection_key",
		"selected_indices_for_entries",
		"page_cache_key",
		"state_for_slot_selection",
		"state_for_part_group_selection",
		"state_for_filter_selection",
		"source_signature_for_slots",
		"collect_raw_entries",
		"build_page_models",
		"has_part_group",
		"part_group_for_slot",
		"default_filter_for_slot",
		"preferred_filter_for_part_group",
		"visible_part_group_slots",
		"part_group_name",
		"filter_option_name",
		"filter_options_for_group",
		"slot_keys_from_filter_option",
		"primary_slot_from_filter_option",
		"catalog_slots_for_filter",
		"available_sort_keys_from_entries",
		"sort_entries",
		"clear_catalog_caches",
	]:
		if controller_source.find(token) < 0:
			_fail("UnitEditorCatalogController missing token: %s" % token)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const UnitEditorCatalogController = preload(\"res://scripts/controllers/unit_editor_catalog_controller.gd\")",
		"var unit_editor_catalog_controller: UnitEditorCatalogController",
		"unit_editor_catalog_controller = UnitEditorCatalogController.new()",
		"unit_editor_catalog_controller.raw_cache_key",
		"unit_editor_catalog_controller.entries_cache_key",
		"unit_editor_catalog_controller.page_selection_key",
		"unit_editor_catalog_controller.page_cache_key",
		"unit_editor_catalog_controller.state_for_slot_selection",
		"unit_editor_catalog_controller.state_for_part_group_selection",
		"unit_editor_catalog_controller.state_for_filter_selection",
		"unit_editor_catalog_controller.source_signature_for_slots",
		"unit_editor_catalog_controller.collect_raw_entries",
		"unit_editor_catalog_controller.build_page_models",
		"unit_editor_catalog_controller.part_group_for_slot",
		"unit_editor_catalog_controller.default_filter_for_slot",
		"unit_editor_catalog_controller.preferred_filter_for_part_group",
		"unit_editor_catalog_controller.visible_part_group_slots",
		"unit_editor_catalog_controller.part_group_name",
		"unit_editor_catalog_controller.filter_option_name",
		"unit_editor_catalog_controller.filter_options_for_group",
		"_all_part_filter_options_for_group",
		"unit_editor_catalog_controller.slot_keys_from_filter_option",
		"unit_editor_catalog_controller.primary_slot_from_filter_option",
		"unit_editor_catalog_controller.catalog_slots_for_filter",
		"unit_editor_catalog_controller.available_sort_keys_from_entries",
		"unit_editor_catalog_controller.sort_entries",
		"unit_editor_catalog_controller.clear_catalog_caches",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate catalog controller boundary token: %s" % token)
	var controller = UnitEditorCatalogControllerScript.new()
	var raw_key := controller.raw_cache_key("hero", "muscle", "weapons", "terminal", "gun", "rifle", "muscle:12")
	if raw_key != "hero|muscle|weapons|terminal|gun|rifle|muscle:12":
		_fail("raw_cache_key returned unexpected key: %s" % raw_key)
	var entries_key := controller.entries_cache_key("hero", "muscle", "weapons", "terminal", "gun", "rifle", "cost", false, "muscle:12")
	if entries_key != "hero|muscle|weapons|terminal|gun|rifle|cost|false|muscle:12":
		_fail("entries_cache_key returned unexpected key: %s" % entries_key)
	var selection_key := controller.page_selection_key([
		{"slot": "muscle"},
		{"slot": "joint"},
	], {"muscle": 4, "joint": 2}, "muscle", 7, true)
	if selection_key != "joint:2,muscle:4,pending:muscle:7:1":
		_fail("page_selection_key returned unexpected key: %s" % selection_key)
	var page_entries_for_selection := [
		{"slot": "muscle", "index": 0},
		{"slot": "module", "index": 1},
		{"slot": "muscle", "index": 2},
	]
	var selected_indices := controller.selected_indices_for_entries(page_entries_for_selection, "hero", {"selected": {"muscle": 2, "module": 1}}, "muscle", Callable(self, "_selected_index_for_probe"))
	if selected_indices != {"muscle": 2, "module": 1}:
		_fail("selected_indices_for_entries returned unexpected map: %s" % str(selected_indices))
	var page_key := controller.page_cache_key(entries_key, 3, 12, "zh", selection_key)
	if page_key != "%s|page:3|size:12|lang:zh|sel:%s" % [entries_key, selection_key]:
		_fail("page_cache_key returned unexpected key: %s" % page_key)
	var build_slots := ["special", "limb_muscle", "muscle", "booster", "engine", "cooling", "module"]
	var slot_state: Dictionary = controller.state_for_slot_selection(3, build_slots)
	if int(slot_state.get("slot_index", -1)) != 3 or String(slot_state.get("part_group_mode", "")) != "software_muscle" or String(slot_state.get("part_filter_mode", "")) != "booster":
		_fail("state_for_slot_selection returned unexpected booster state: %s" % str(slot_state))
	var clamped_slot_state: Dictionary = controller.state_for_slot_selection(999, build_slots)
	if int(clamped_slot_state.get("slot_index", -1)) != build_slots.size() - 1 or String(clamped_slot_state.get("part_filter_mode", "")) != "module":
		_fail("state_for_slot_selection should clamp slot index.")
	var group_state: Dictionary = controller.state_for_part_group_selection("software", "barrier", "muscle", build_slots)
	if String(group_state.get("part_filter_mode", "")) != "ether" or int(group_state.get("slot_index", -1)) != 0:
		_fail("state_for_part_group_selection should choose role-specific preferred software filter and slot.")
	var weapon_group_state: Dictionary = controller.state_for_part_group_selection("terminal_weapon", "hero", "special", build_slots)
	if String(weapon_group_state.get("part_filter_mode", "")) != "weapon_all" or int(weapon_group_state.get("slot_index", -1)) != 2:
		_fail("state_for_part_group_selection should choose weapon_all and muscle slot for terminal weapons.")
	var invalid_group_state: Dictionary = controller.state_for_part_group_selection("unknown_group", "hero", "muscle", build_slots)
	if bool(invalid_group_state.get("valid", true)):
		_fail("state_for_part_group_selection should reject unknown groups.")
	var gun_filter_state: Dictionary = controller.state_for_filter_selection(2, "terminal_weapon", "muscle", build_slots)
	if String(gun_filter_state.get("part_filter_mode", "")) != "weapon_gun" or String(gun_filter_state.get("weapon_filter_group", "")) != "gun" or String(gun_filter_state.get("weapon_filter_subtype", "")) != "all":
		_fail("state_for_filter_selection should enter gun submenu state.")
	var sniper_filter_state: Dictionary = controller.state_for_filter_selection(3, "terminal_weapon", "muscle", build_slots, "gun")
	if String(sniper_filter_state.get("part_filter_mode", "")) != "gun_sniper" or String(sniper_filter_state.get("weapon_filter_group", "")) != "gun" or String(sniper_filter_state.get("weapon_filter_subtype", "")) != "sniper":
		_fail("state_for_filter_selection should preserve gun submenu context.")
	var ammo_filter_state: Dictionary = controller.state_for_filter_selection(3, "software_muscle", "engine", build_slots)
	if String(ammo_filter_state.get("part_filter_mode", "")) != "ammo" or int(ammo_filter_state.get("slot_index", -1)) != 2 or String(ammo_filter_state.get("weapon_filter_group", "")) != "all":
		_fail("state_for_filter_selection should switch equipment ammo filter to muscle slot and reset weapon state.")
	var invalid_filter_state: Dictionary = controller.state_for_filter_selection(99, "software_muscle", "engine", build_slots)
	if bool(invalid_filter_state.get("valid", true)):
		_fail("state_for_filter_selection should reject out-of-range filter indices.")
	var source_signature := controller.source_signature_for_slots(["muscle", "module"], "hero", Callable(self, "_catalog_for_probe"))
	if source_signature != "muscle:3,module:2":
		_fail("source_signature_for_slots returned unexpected signature: %s" % source_signature)
	var raw_entries := controller.collect_raw_entries(
		"hero",
		["muscle", "module"],
		Callable(self, "_catalog_for_probe"),
		Callable(self, "_selected_component_for_probe"),
		Callable(self, "_passes_filter_for_probe"),
		Callable(self, "_display_part_for_probe")
	)
	if raw_entries.size() != 3:
		_fail("collect_raw_entries should preserve only entries accepted by delegated filter.")
	if String(Dictionary(raw_entries[0]).get("slot", "")) != "muscle" or int(Dictionary(raw_entries[0]).get("index", -1)) != 0:
		_fail("collect_raw_entries should preserve slot/index order.")
	var displayed: Dictionary = Dictionary(Dictionary(raw_entries[0]).get("display_part", {}))
	if not bool(displayed.get("display", false)):
		_fail("collect_raw_entries should use delegated display part.")
	var page_models := controller.build_page_models(
		[
			{"slot": "muscle", "index": 0, "part": {"name": "weapon-a"}, "display_part": {"name": "weapon-a", "stable_key": "wa"}},
			{"slot": "module", "index": 1, "part": {"name": "module-b"}},
		],
		"hero",
		{"selected": {"muscle": 0, "module": 1}},
		"muscle",
		"zh",
		true,
		Callable(self, "_selected_index_for_probe"),
		Callable(self, "_display_part_for_probe"),
		Callable(self, "_selected_component_for_probe"),
		Callable(self, "_card_model_for_probe")
	)
	if page_models.size() != 2:
		_fail("build_page_models should build one model per valid page entry.")
	if String(Dictionary(page_models[0]).get("title", "")) != "待选 weapon-a":
		_fail("build_page_models should add pending marker for selected topology parts.")
	if String(Dictionary(page_models[1]).get("title", "")) != "已装 module-b":
		_fail("build_page_models should add installed marker for selected non-topology parts.")
	if String(Dictionary(page_models[1]).get("signature", "")).find("zh|已装 module-b") < 0:
		_fail("build_page_models should include language and title in card signature.")
	if not controller.has_part_group("terminal_weapon") or controller.has_part_group("unknown_group"):
		_fail("has_part_group should recognize only known catalog groups.")
	if controller.part_group_for_slot("limb_muscle") != "limb":
		_fail("part_group_for_slot should map limb_muscle to limb.")
	if controller.part_group_for_slot("booster") != "software_muscle":
		_fail("part_group_for_slot should map booster to software_muscle.")
	if controller.part_group_for_slot("unknown_slot") != "terminal_weapon":
		_fail("part_group_for_slot should fallback to terminal_weapon.")
	if controller.default_filter_for_slot("muscle") != "weapon_all":
		_fail("default_filter_for_slot should map muscle to weapon_all.")
	if controller.default_filter_for_slot("unknown_slot") != "all":
		_fail("default_filter_for_slot should fallback to all.")
	if controller.preferred_filter_for_part_group("software", "hero") != "soul":
		_fail("preferred_filter_for_part_group should use role-specific software defaults.")
	if controller.preferred_filter_for_part_group("software", "puppet") != "code":
		_fail("preferred_filter_for_part_group should use puppet software default.")
	if controller.preferred_filter_for_part_group("software", "barrier") != "ether":
		_fail("preferred_filter_for_part_group should use barrier software default.")
	if controller.preferred_filter_for_part_group("software", "unknown_role") != "module":
		_fail("preferred_filter_for_part_group should fallback software to module.")
	if controller.preferred_filter_for_part_group("terminal_weapon") != "weapon_all":
		_fail("preferred_filter_for_part_group should map terminal weapons to weapon_all.")
	if controller.visible_part_group_slots("software_muscle") != ["engine", "booster", "cooling", "muscle"]:
		_fail("visible_part_group_slots should return software equipment slots.")
	if controller.visible_part_group_slots("unknown_group") != ["muscle"]:
		_fail("visible_part_group_slots should fallback to terminal weapon slots.")
	if controller.part_group_name("barrier_panel", true) != "结界板":
		_fail("part_group_name should return zh labels.")
	if controller.part_group_name("software_muscle", false) != "EQUIPMENT":
		_fail("part_group_name should return en labels.")
	if controller.part_group_name("unknown_group", false) != "UNKNOWN_GROUP":
		_fail("part_group_name should fallback to uppercase keys.")
	if controller.filter_option_name({"key": "weapon_all", "zh": "全部", "en": "ALL"}, true) != "全部":
		_fail("filter_option_name should return zh option labels.")
	if controller.filter_option_name({"key": "weapon_all", "zh": "全部", "en": "all"}, false) != "ALL":
		_fail("filter_option_name should uppercase en option labels.")
	var weapon_all := controller.filter_options_for_group("terminal_weapon", "all")
	var weapon_melee := controller.filter_options_for_group("terminal_weapon", "melee")
	var weapon_gun := controller.filter_options_for_group("terminal_weapon", "gun")
	var weapon_audit := controller.filter_options_for_group("terminal_weapon", "all", true)
	if weapon_all.size() != 3 or weapon_melee.size() <= weapon_all.size() or weapon_gun.size() <= weapon_all.size():
		_fail("terminal weapon filter options should expand for melee/gun submenus.")
	if String(Dictionary(weapon_melee[3]).get("key", "")) != "weapon_blade":
		_fail("melee submenu should expose blade filter after base weapon options.")
	if String(Dictionary(weapon_gun[3]).get("key", "")) != "gun_sniper":
		_fail("gun submenu should expose sniper filter after base weapon options.")
	var audit_keys: Array = []
	for raw_option in weapon_audit:
		audit_keys.append(String(Dictionary(raw_option).get("key", "")))
	for expected_key in ["terminal", "terminal_melee", "terminal_ranged", "weapon_scythe", "weapon_gauntlet", "gun_web"]:
		if not audit_keys.has(expected_key):
			_fail("rule-audit filter options missing key: %s" % expected_key)
	var barrier_slots := controller.slot_keys_from_filter_option({"key": "barrier_muscle", "slots": ["limb_muscle", "muscle", "muscle"]})
	if barrier_slots != ["limb_muscle", "muscle"]:
		_fail("slot_keys_from_filter_option should preserve unique multi-slot order.")
	if controller.primary_slot_from_filter_option({"slots": ["limb_muscle", "muscle"]}, "joint") != "limb_muscle":
		_fail("primary_slot_from_filter_option should return the first declared slot.")
	if controller.catalog_slots_for_filter("muscle", "barrier_panel", "barrier_muscle") != ["limb_muscle", "muscle"]:
		_fail("catalog_slots_for_filter should resolve multi-slot barrier filter.")
	if controller.catalog_slots_for_filter("muscle", "terminal_weapon", "gun_web", "gun") != ["muscle"]:
		_fail("catalog_slots_for_filter should resolve terminal weapon gun subfilters.")
	var sort_entries := [
		{"slot": "muscle", "index": 3, "display_part": {"cost": 30.0, "mass": 2.0}},
		{"slot": "muscle", "index": 1, "display_part": {"cost": 10.0, "mass": 5.0}},
		{"slot": "joint", "index": 2, "display_part": {"mass": 1.0}},
	]
	var keys := controller.available_sort_keys_from_entries(sort_entries, ["cost", "mass", "range"], Callable(self, "_has_sort_property_for_probe"))
	if keys != ["cost", "mass"]:
		_fail("available_sort_keys_from_entries returned unexpected keys: %s" % str(keys))
	controller.sort_entries(sort_entries, "muscle", Callable(self, "_sort_value_for_probe").bind("cost"), true)
	if int(Dictionary(sort_entries[0]).get("index", -1)) != 2 or int(Dictionary(sort_entries[1]).get("index", -1)) != 1:
		_fail("sort_entries should order ascending by delegated sort value with stable index tie fallback.")
	controller.sort_entries(sort_entries, "muscle", Callable(self, "_sort_value_for_probe").bind("mass"), false)
	if int(Dictionary(sort_entries[0]).get("index", -1)) != 1:
		_fail("sort_entries should order descending by delegated sort value.")
	var raw_cache := {"a": 1}
	var entries_cache := {"b": 2}
	var sort_cache := {"c": 3}
	var card_cache := {"d": 4}
	var page_cache := {"e": 5}
	var load_cache := {"f": 6}
	controller.clear_catalog_caches(raw_cache, entries_cache, sort_cache, card_cache, page_cache, load_cache)
	if raw_cache.size() + entries_cache.size() + sort_cache.size() + card_cache.size() + page_cache.size() + load_cache.size() != 0:
		_fail("clear_catalog_caches should empty all catalog-local caches.")
	print("UNIT_EDITOR_CATALOG_CONTROLLER_CONTRACT_PROBE ok")
	quit(0)


func _has_sort_property_for_probe(_slot_key: String, part: Dictionary, sort_key: String) -> bool:
	return part.has(sort_key)


func _sort_value_for_probe(slot_key: String, part: Dictionary, sort_key: String) -> float:
	if slot_key == "joint" and sort_key == "cost":
		return 0.0
	return float(part.get(sort_key, 0.0))


func _catalog_for_probe(_role_key: String, slot_key: String) -> Array:
	match slot_key:
		"muscle":
			return [
				{"name": "weapon-a", "cost": 10.0, "visible": true},
				{"name": "weapon-b", "cost": 20.0, "visible": false},
				{"name": "weapon-c", "cost": 30.0, "visible": true},
			]
		"module":
			return [
				{"name": "module-a", "cost": 3.0, "visible": false},
				{"name": "module-b", "cost": 4.0, "visible": true},
			]
	return []


func _selected_component_for_probe(role_key: String, slot_key: String, index: int) -> Dictionary:
	return Dictionary(_catalog_for_probe(role_key, slot_key)[index])


func _passes_filter_for_probe(_slot_key: String, part: Dictionary) -> bool:
	return bool(part.get("visible", false))


func _display_part_for_probe(_slot_key: String, part: Dictionary) -> Dictionary:
	var display := part.duplicate()
	display["display"] = true
	return display


func _selected_index_for_probe(unit_bp: Dictionary, _role_key: String, slot_key: String) -> int:
	return int(Dictionary(unit_bp.get("selected", {})).get(slot_key, -1))


func _card_model_for_probe(_slot_key: String, part: Dictionary, _part_index: int) -> Dictionary:
	return {
		"title_base": String(part.get("name", "")),
		"line_a": "A",
		"line_b": "B",
	}
