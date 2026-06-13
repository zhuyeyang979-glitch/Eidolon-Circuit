extends SceneTree

const CONTROLLER_PATH := "res://scripts/controllers/saved_units_controller.gd"
const MAIN_PATH := "res://scripts/main.gd"
const SavedUnitsControllerScript := preload("res://scripts/controllers/saved_units_controller.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(CONTROLLER_PATH):
		_fail("Missing SavedUnitsController script.")
		return
	var controller_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(CONTROLLER_PATH))
	for token in [
		"class_name SavedUnitsController",
		"filtered_cache_key",
		"entry_path",
		"filter_entries",
			"absolute_index_for_card",
			"page_for_focus_path",
			"focus_state_for_path",
			"selection_state_for_filter",
			"selection_state_for_card",
			"hover_state_for_card",
		"selected_entries",
			"delete_candidates",
			"delete_request_intent",
			"post_delete_selection_state",
			"toggle_selection_state",
			"page_action_state",
	]:
		if controller_source.find(token) < 0:
			_fail("SavedUnitsController missing token: %s" % token)
			return
	for forbidden in ["FileAccess", "DirAccess", "JSON.parse_string", "Button", "extends Control", "Control.new"]:
		if controller_source.find(forbidden) >= 0:
			_fail("SavedUnitsController should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const SavedUnitsController = preload(\"res://scripts/controllers/saved_units_controller.gd\")",
		"var saved_units_controller: SavedUnitsController",
			"saved_units_controller = SavedUnitsController.new()",
			"saved_units_controller.filtered_cache_key",
			"saved_units_controller.filter_entries",
			"saved_units_controller.focus_state_for_path",
			"saved_units_controller.selection_state_for_filter",
			"saved_units_controller.selection_state_for_card",
			"saved_units_controller.hover_state_for_card",
			"saved_units_controller.selected_entries",
			"saved_units_controller.delete_candidates",
			"saved_units_controller.delete_request_intent",
			"saved_units_controller.post_delete_selection_state",
			"saved_units_controller.toggle_selection_state",
			"saved_units_controller.page_action_state",
		"_apply_saved_unit_selection_state",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate saved-units controller token: %s" % token)
			return
	var controller = SavedUnitsControllerScript.new()
	if controller.filtered_cache_key("hero", "sig") != "hero|sig":
		_fail("filtered_cache_key returned unexpected key.")
	var entries := [
		{"path": "unit-a.json", "role": "hero", "unit_name": "A", "blueprint": {}},
		{"path": "unit-b.json", "role": "puppet", "unit_name": "B", "blueprint": {}},
		{"path": "unit-c.json", "role": "hero", "unit_name": "C", "blueprint": {}, "load_rejection_reason": "bad"},
		{"path": "unit-d.json", "role": "barrier", "unit_name": "D", "blueprint": {}, "canonical_rejected": true},
		"skip-me",
	]
	if controller.filter_entries(entries, "all").size() != 4:
		_fail("filter_entries(all) should include all dictionary entries.")
	if _entry_names(controller.filter_entries(entries, "hero")) != ["A", "C"]:
		_fail("filter_entries(hero) should preserve hero entries in order.")
	if _entry_names(controller.filter_entries(entries, "puppet")) != ["B"]:
		_fail("filter_entries(puppet) should preserve puppet entries.")
	if _entry_names(controller.filter_entries(entries, "invalid")) != ["C", "D"]:
		_fail("filter_entries(invalid) should use fallback invalid fields without a callback.")
	if _entry_names(controller.filter_entries(entries, "invalid", Callable(self, "_illegal_note_for_probe"))) != ["B", "C", "D"]:
		_fail("filter_entries(invalid) should use delegated illegal note callback when supplied.")
	var focus_state: Dictionary = controller.page_for_focus_path(entries, "unit-c.json", 2)
	if not bool(focus_state.get("found", false)) or int(focus_state.get("selected_index", -1)) != 2 or int(focus_state.get("page", -1)) != 1:
		_fail("page_for_focus_path returned unexpected found state: %s" % str(focus_state))
	var missing_state: Dictionary = controller.page_for_focus_path(entries, "missing.json", 2)
	if bool(missing_state.get("found", true)) or int(missing_state.get("selected_index", 0)) != -1:
		_fail("page_for_focus_path should no-op for missing paths.")
	var rejected_focus: Dictionary = controller.focus_state_for_path(entries, "unit-d.json", 2, 7)
	if not bool(rejected_focus.get("found", false)) or not bool(rejected_focus.get("rejected", false)) or int(rejected_focus.get("saved_unit_selected_index", -1)) != 3:
		_fail("focus_state_for_path should select rejected focused entries: %s" % str(rejected_focus))
	if int(rejected_focus.get("saved_unit_page", -1)) != 1 or String(rejected_focus.get("saved_unit_detail_path", "")) != "unit-d.json":
		_fail("focus_state_for_path should keep rejected detail visible on the correct page: %s" % str(rejected_focus))
	if String(rejected_focus.get("focus_notice_key", "")) != "focus_rejected" or String(rejected_focus.get("focus_notice_reason", "")) == "":
		_fail("focus_state_for_path should preserve rejected focus reasons: %s" % str(rejected_focus))
	var missing_focus: Dictionary = controller.focus_state_for_path(entries, "missing.json", 2, 7)
	if bool(missing_focus.get("found", true)) or not bool(missing_focus.get("missing", false)):
		_fail("focus_state_for_path should flag missing focused paths: %s" % str(missing_focus))
	if int(missing_focus.get("saved_unit_page", -1)) != 2 or int(missing_focus.get("saved_unit_selected_index", 0)) != -1:
		_fail("focus_state_for_path should clamp the current page and clear missing selection: %s" % str(missing_focus))
	if String(missing_focus.get("saved_unit_hovered_path", "x")) != "" or String(missing_focus.get("saved_unit_detail_path", "x")) != "":
		_fail("focus_state_for_path should clear stale hover/detail for missing focus: %s" % str(missing_focus))
	var filter_state: Dictionary = controller.selection_state_for_filter("invalid")
	if String(filter_state.get("saved_unit_filter", "")) != "invalid" or int(filter_state.get("saved_unit_page", -1)) != 0 or int(filter_state.get("saved_unit_selected_index", 0)) != -1:
		_fail("selection_state_for_filter should reset page and selected state.")
	if String(filter_state.get("saved_unit_hovered_path", "x")) != "" or String(filter_state.get("saved_unit_detail_path", "x")) != "":
		_fail("selection_state_for_filter should clear hover and detail state.")
	var card_state: Dictionary = controller.selection_state_for_card(1, 1, 2, entries)
	if not bool(card_state.get("valid", false)) or int(card_state.get("saved_unit_selected_index", -1)) != 3 or String(card_state.get("saved_unit_hovered_path", "")) != "unit-d.json":
		_fail("selection_state_for_card returned unexpected card state: %s" % str(card_state))
	var invalid_card_state: Dictionary = controller.selection_state_for_card(9, 1, 2, entries)
	if bool(invalid_card_state.get("valid", true)):
		_fail("selection_state_for_card should reject out-of-range cards.")
	var hover_state: Dictionary = controller.hover_state_for_card(0, 1, 2, entries, "unit-c.json", 2)
	if not bool(hover_state.get("valid", false)) or bool(hover_state.get("changed", true)):
		_fail("hover_state_for_card should treat the same absolute entry as unchanged.")
	var changed_hover_state: Dictionary = controller.hover_state_for_card(1, 1, 2, entries, "unit-c.json", 2)
	if not bool(changed_hover_state.get("valid", false)) or not bool(changed_hover_state.get("changed", false)) or String(changed_hover_state.get("saved_unit_hovered_path", "")) != "unit-d.json":
		_fail("hover_state_for_card should expose changed hover state.")
	if _entry_names(controller.selected_entries(entries, ["unit-b.json", "unit-d.json"])) != ["B", "D"]:
		_fail("selected_entries should return entries whose paths are selected.")
	var delete_from_paths := controller.delete_candidates(entries, ["unit-b.json"], 2)
	if _entry_names(delete_from_paths) != ["B"]:
		_fail("delete_candidates should prefer explicit selected paths.")
	var delete_from_fallback := controller.delete_candidates(entries, [], 0, {"path": "unit-c.json", "unit_name": "C"})
	if _entry_names(delete_from_fallback) != ["C"]:
		_fail("delete_candidates should use the filtered selected entry fallback.")
	var delete_intent: Dictionary = controller.delete_request_intent([
		{"path": "unit-a.json", "unit_name": "A"},
		{"path": "unit-a.json", "unit_name": "Duplicate A"},
		{"path": "unit-b.json", "unit_name": "B"},
		{"path": "unit-c.json", "unit_name": "C"},
		{"path": "unit-d.json", "unit_name": "D"},
		{"path": "unit-e.json", "unit_name": "E"},
	])
	if not bool(delete_intent.get("valid", false)) or Array(delete_intent.get("pending_delete_paths", [])).size() != 5 or String(delete_intent.get("summary", "")) != "A, B, C, D...":
		_fail("delete_request_intent should dedupe paths and summarize names: %s" % str(delete_intent))
	var delete_repair: Dictionary = controller.post_delete_selection_state([
		entries[0],
		entries[2],
		entries[3],
	], ["unit-b.json"], 1, 0, 2)
	if int(delete_repair.get("saved_unit_selected_index", -1)) != 1 or String(delete_repair.get("saved_unit_hovered_path", "")) != "unit-c.json":
		_fail("post_delete_selection_state should repair selection to the next neighbor: %s" % str(delete_repair))
	var delete_last_repair: Dictionary = controller.post_delete_selection_state([
		entries[0],
		entries[1],
		entries[2],
	], ["unit-d.json"], 3, 1, 2)
	if int(delete_last_repair.get("saved_unit_selected_index", -1)) != 2 or int(delete_last_repair.get("saved_unit_page", -1)) != 1:
		_fail("post_delete_selection_state should clamp deleted-last selection onto the last remaining page: %s" % str(delete_last_repair))
	var delete_empty_repair: Dictionary = controller.post_delete_selection_state([], ["unit-a.json"], 0, 0, 2)
	if int(delete_empty_repair.get("saved_unit_selected_index", 0)) != -1 or String(delete_empty_repair.get("saved_unit_detail_path", "x")) != "":
		_fail("post_delete_selection_state should clear selection when no entries remain: %s" % str(delete_empty_repair))
	var toggle_state: Dictionary = controller.toggle_selection_state({"path": "unit-a.json", "unit_name": "A"}, ["unit-b.json"])
	if not bool(toggle_state.get("valid", false)) or Array(toggle_state.get("saved_unit_selected_paths", [])) != ["unit-b.json", "unit-a.json"] or String(toggle_state.get("saved_unit_detail_path", "x")) != "":
		_fail("toggle_selection_state should add unselected paths and clear detail.")
	var untoggle_state: Dictionary = controller.toggle_selection_state({"path": "unit-b.json", "unit_name": "B"}, ["unit-b.json", "unit-a.json"])
	if Array(untoggle_state.get("saved_unit_selected_paths", [])) != ["unit-a.json"]:
		_fail("toggle_selection_state should remove selected paths.")
	var rejected_toggle: Dictionary = controller.toggle_selection_state({"path": "unit-d.json", "canonical_rejected": true}, ["unit-a.json"], "bad unit")
	if bool(rejected_toggle.get("valid", true)) or String(rejected_toggle.get("reason", "")) != "bad unit":
		_fail("toggle_selection_state should reject canonical-rejected entries with reason.")
	var next_page: Dictionary = controller.page_action_state("next", 0, 2, 5, 0, [])
	if int(next_page.get("saved_unit_page", -1)) != 1:
		_fail("page_action_state(next) should increment within max page.")
	var clamped_next_page: Dictionary = controller.page_action_state("next", 2, 2, 5, 0, [])
	if int(clamped_next_page.get("saved_unit_page", -1)) != 2:
		_fail("page_action_state(next) should clamp at max page.")
	var clear_state: Dictionary = controller.page_action_state("clear", 0, 2, 5, 0, ["unit-a.json"])
	if Array(clear_state.get("saved_unit_selected_paths", ["x"])) != []:
		_fail("page_action_state(clear) should clear selected paths.")
	var page_toggle: Dictionary = controller.page_action_state("toggle", 0, 2, 5, 0, ["unit-a.json"], {"path": "unit-b.json", "unit_name": "B"})
	if not bool(page_toggle.get("valid", false)) or Array(page_toggle.get("saved_unit_selected_paths", [])) != ["unit-a.json", "unit-b.json"]:
		_fail("page_action_state(toggle) should delegate selection toggling.")
	if controller.absolute_index_for_card(3, 2, 0) != 5:
		_fail("absolute_index_for_card should clamp zero page size to one.")
	var fallback_entry_path := controller.entry_path({"unit_id": "id-a", "unit_name": "name-a"})
	if fallback_entry_path != "id-a":
		_fail("entry_path should prefer unit_id when path is absent.")
	print("SAVED_UNITS_CONTROLLER_CONTRACT_PROBE ok")
	quit(0)


func _entry_names(entries: Array) -> Array:
	var names: Array = []
	for raw_entry in entries:
		names.append(String(Dictionary(raw_entry).get("unit_name", "")))
	return names


func _illegal_note_for_probe(entry: Dictionary) -> String:
	if String(entry.get("unit_name", "")) == "B":
		return "callback invalid"
	if String(entry.get("load_rejection_reason", "")) != "":
		return String(entry.get("load_rejection_reason", ""))
	if bool(entry.get("canonical_rejected", false)):
		return "canonical invalid"
	return ""
