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
		"_commit_saved_units_mode_enter(nav_reason, payload)",
		"_commit_saved_units_mode_exit(reason, payload)",
		"_cleanup_saved_units_page_runtime(reason, payload)",
		"var show_intent := _saved_units_mode_show_intent(focus_path, resolved_return_context, defer_disk_scan, preloaded, loading_queued)",
		"saved_units_return_context = String(show_intent.get(\"return_context\", resolved_return_context))",
		"var cleanup_intent := _saved_units_cleanup_intent(reason, payload)",
		"_commit_saved_units_cleanup(cleanup_intent)",
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
	var exit_intent: Dictionary = mode.exit_intent("navigate")
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("SavedUnitsMode commit_exit failed.")
		return
	print("SAVED_UNITS_MODE_CONTRACT_PROBE ok")
	quit(0)
