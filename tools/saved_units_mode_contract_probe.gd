extends SceneTree

const MODE_PATH := "res://scripts/modes/saved_units_mode.gd"
const MAIN_PATH := "res://scripts/main.gd"
const SavedUnitsModeScript := preload("res://scripts/modes/saved_units_mode.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		_fail("Missing SavedUnitsMode script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MODE_PATH))
	for token in [
		"class_name SavedUnitsMode",
		"MODE_KEY := \"saved_units\"",
		"func bind",
		"func show_intent",
		"func enter_intent",
		"func commit_enter",
		"func cleanup_intent",
		"func commit_cleanup",
		"func filter_intent",
		"func card_select_intent",
		"func card_pointer_intent",
		"func input_intent",
		"func action_intent",
		"func exit_intent",
		"func commit_exit",
	]:
		if source.find(token) < 0:
			_fail("SavedUnitsMode missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "_ensure_saved_unit_library_cache", "_import_saved_unit_entries_to_training", "_load_saved_unit_entry_into_unit_editor"]:
		if source.find(forbidden) >= 0:
			_fail("SavedUnitsMode should stay saved-units-boundary only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const SavedUnitsMode = preload(\"res://scripts/modes/saved_units_mode.gd\")",
		"var saved_units_mode_owner: SavedUnitsMode",
		"saved_units_mode_owner = SavedUnitsMode.new()",
		"saved_units_mode_owner.bind(self, saved_units_controller)",
		"func _commit_saved_units_mode_enter",
		"func _commit_saved_units_mode_exit",
		"saved_units_mode_owner.enter_intent",
		"saved_units_mode_owner.commit_enter",
		"saved_units_mode_owner.exit_intent",
		"saved_units_mode_owner.commit_exit",
		"func _saved_units_mode_show_intent",
		"saved_units_mode_owner.show_intent",
		"func _saved_units_cleanup_intent",
		"saved_units_mode_owner.cleanup_intent",
		"func _commit_saved_units_cleanup",
		"saved_units_mode_owner.commit_cleanup",
		"func _saved_units_filter_intent",
		"saved_units_mode_owner.filter_intent",
		"func _apply_saved_units_filter_intent",
		"func _saved_units_card_select_intent",
		"saved_units_mode_owner.card_select_intent",
		"func _saved_units_card_pointer_intent",
		"saved_units_mode_owner.card_pointer_intent",
		"func _apply_saved_units_card_pointer_intent",
		"func _saved_units_input_intent",
		"saved_units_mode_owner.input_intent",
		"func _apply_saved_units_input_intent",
		"func _saved_units_action_intent",
		"saved_units_mode_owner.action_intent",
		"func _apply_saved_units_action_intent",
		"_commit_saved_units_mode_enter(nav_reason, payload)",
		"_commit_saved_units_mode_exit(reason, payload)",
		"_cleanup_saved_units_page_runtime(reason, payload)",
		"var show_intent := _saved_units_mode_show_intent(focus_path, resolved_return_context, defer_disk_scan, preloaded, loading_queued)",
		"saved_units_return_context = String(show_intent.get(\"return_context\", resolved_return_context))",
		"var cleanup_intent := _saved_units_cleanup_intent(reason, payload)",
		"_commit_saved_units_cleanup(cleanup_intent)",
		"_apply_saved_units_input_intent(_saved_units_input_intent(\"menu_back\"))",
		"_apply_saved_units_action_intent(_saved_units_action_intent(action_key))",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing SavedUnitsMode wiring token: %s" % token)
			return
	var mode = SavedUnitsModeScript.new()
	if mode.mode_key() != "saved_units":
		_fail("SavedUnitsMode mode_key mismatch: %s" % mode.mode_key())
		return
	var show_wait: Dictionary = mode.show_intent("", "menu", true, false, true)
	if bool(show_wait.get("should_apply", true)) or not bool(show_wait.get("loading_queued", false)) or not bool(show_wait.get("defer_disk_scan", false)):
		_fail("SavedUnitsMode queued show_intent mismatch: %s" % str(show_wait))
		return
	var show_now: Dictionary = mode.show_intent("user://saved_units/a.json", "editor", false, true, false)
	if not bool(show_now.get("should_apply", false)) or String(show_now.get("focus_path", "")) != "user://saved_units/a.json" or String(show_now.get("return_context", "")) != "editor":
		_fail("SavedUnitsMode apply show_intent mismatch: %s" % str(show_now))
		return
	var enter_intent: Dictionary = mode.enter_intent("saved_units", {"focus_path": "x"})
	if not mode.commit_enter(enter_intent) or mode.enter_count != 1:
		_fail("SavedUnitsMode commit_enter failed.")
		return
	if mode.commit_enter({"mode_key": "menu"}):
		_fail("SavedUnitsMode should reject wrong-mode enter commits.")
		return
	var cleanup_intent: Dictionary = mode.cleanup_intent("navigate", {"focus_path": "x"})
	for key in ["clear_hover", "clear_focus", "clear_detail", "clear_pending_delete"]:
		if not bool(cleanup_intent.get(key, false)):
			_fail("SavedUnitsMode cleanup_intent missing flag %s: %s" % [key, str(cleanup_intent)])
			return
	if not mode.commit_cleanup(cleanup_intent) or String(mode.last_cleanup_context.get("reason", "")) != "navigate":
		_fail("SavedUnitsMode commit_cleanup failed.")
		return
	var default_filter: Dictionary = mode.filter_intent("")
	if not bool(default_filter.get("handled", false)) or String(default_filter.get("kind", "")) != "filter" or String(default_filter.get("filter_key", "")) != "all":
		_fail("SavedUnitsMode empty filter should resolve to all: %s" % str(default_filter))
		return
	var puppet_filter: Dictionary = mode.filter_intent("puppet")
	if String(puppet_filter.get("filter_key", "")) != "puppet" or not bool(puppet_filter.get("clear_selection", false)) or not bool(puppet_filter.get("clear_hover", false)):
		_fail("SavedUnitsMode filter intent mismatch: %s" % str(puppet_filter))
		return
	var card_select: Dictionary = mode.card_select_intent(5, 2, 12, 30)
	if not bool(card_select.get("handled", false)) or String(card_select.get("kind", "")) != "select_card" or int(card_select.get("absolute_index", -1)) != 29:
		_fail("SavedUnitsMode card_select_intent mismatch: %s" % str(card_select))
		return
	var missing_card: Dictionary = mode.card_select_intent(6, 2, 12, 30)
	if bool(missing_card.get("handled", true)) or int(missing_card.get("absolute_index", -1)) != 30:
		_fail("SavedUnitsMode missing card should be unhandled: %s" % str(missing_card))
		return
	var card_toggle: Dictionary = mode.card_pointer_intent("right", 1, 0, 12, 4)
	if not bool(card_toggle.get("handled", false)) or String(card_toggle.get("kind", "")) != "toggle_card" or int(card_toggle.get("absolute_index", -1)) != 1:
		_fail("SavedUnitsMode right pointer should toggle card: %s" % str(card_toggle))
		return
	var delete_back: Dictionary = mode.input_intent("menu_back", 2, 5, 12, true)
	if not bool(delete_back.get("handled", false)) or String(delete_back.get("kind", "")) != "cancel_delete":
		_fail("SavedUnitsMode back with delete panel should cancel delete: %s" % str(delete_back))
		return
	var page_back: Dictionary = mode.input_intent("menu_back", 2, 5, 12, false)
	if not bool(page_back.get("handled", false)) or String(page_back.get("kind", "")) != "show_options":
		_fail("SavedUnitsMode back should show options: %s" % str(page_back))
		return
	var select_up: Dictionary = mode.input_intent("menu_up", 0, 5, 3, false)
	if not bool(select_up.get("handled", false)) or int(select_up.get("selected_index", -1)) != 0 or int(select_up.get("page", -1)) != 0:
		_fail("SavedUnitsMode menu_up should clamp at first entry: %s" % str(select_up))
		return
	var select_down: Dictionary = mode.input_intent("menu_down", 2, 5, 3, false)
	if not bool(select_down.get("handled", false)) or int(select_down.get("selected_index", -1)) != 3 or int(select_down.get("page", -1)) != 1:
		_fail("SavedUnitsMode menu_down should advance page-aware selection: %s" % str(select_down))
		return
	var ignored_down: Dictionary = mode.input_intent("menu_down", -1, 0, 12, false)
	if bool(ignored_down.get("handled", true)) or String(ignored_down.get("kind", "")) != "select_index":
		_fail("SavedUnitsMode menu_down should ignore empty entries: %s" % str(ignored_down))
		return
	var edit_missing: Dictionary = mode.action_intent("edit", -1, 4, 0, -1, 0)
	if bool(edit_missing.get("handled", true)) or String(edit_missing.get("kind", "")) != "selected_entry":
		_fail("SavedUnitsMode edit should require selected entry: %s" % str(edit_missing))
		return
	var edit_selected: Dictionary = mode.action_intent("edit", 1, 4, 0, -1, 0)
	if not bool(edit_selected.get("handled", false)) or String(edit_selected.get("kind", "")) != "selected_entry":
		_fail("SavedUnitsMode edit selected action mismatch: %s" % str(edit_selected))
		return
	var team_next: Dictionary = mode.action_intent("team_next", 1, 4, 2, 0, 3)
	if not bool(team_next.get("handled", false)) or String(team_next.get("kind", "")) != "team_cycle":
		_fail("SavedUnitsMode team_next action mismatch: %s" % str(team_next))
		return
	var load_team_missing: Dictionary = mode.action_intent("load_team", 1, 4, 2, -1, 3)
	if bool(load_team_missing.get("handled", true)) or String(load_team_missing.get("kind", "")) != "team_entry":
		_fail("SavedUnitsMode load_team should require a valid team index: %s" % str(load_team_missing))
		return
	var exit_intent: Dictionary = mode.exit_intent("navigate")
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("SavedUnitsMode commit_exit failed.")
		return
	print("SAVED_UNITS_MODE_CONTRACT_PROBE ok")
	quit(0)
