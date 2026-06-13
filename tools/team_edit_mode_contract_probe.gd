extends SceneTree

const MODE_PATH := "res://scripts/modes/team_edit_mode.gd"
const MAIN_PATH := "res://scripts/main.gd"
const TeamEditModeScript := preload("res://scripts/modes/team_edit_mode.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		_fail("Missing TeamEditMode script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MODE_PATH))
	for token in [
		"class_name TeamEditMode",
		"MODE_KEY := \"team_edit\"",
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
			_fail("TeamEditMode missing token: %s" % token)
			return
	for forbidden in ["Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "_save_editor_current_unit", "_show_training_config", "_prepare_training_battle_loadouts", "_reset_editor_working_canvas", "_apply_editor_role_catalog_defaults", "_handle_editor_board_input"]:
		if source.find(forbidden) >= 0:
			_fail("TeamEditMode should stay Team Edit boundary-only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const TeamEditMode = preload(\"res://scripts/modes/team_edit_mode.gd\")",
		"var team_edit_mode_owner: TeamEditMode",
		"team_edit_mode_owner = TeamEditMode.new()",
		"team_edit_mode_owner.bind(self, team_edit_controller)",
		"func _commit_team_edit_mode_enter",
		"func _commit_team_edit_mode_exit",
		"team_edit_mode_owner.enter_intent",
		"team_edit_mode_owner.commit_enter",
		"team_edit_mode_owner.exit_intent",
		"team_edit_mode_owner.commit_exit",
		"func _team_edit_mode_show_intent",
		"team_edit_mode_owner.show_intent",
		"func _team_edit_cleanup_intent",
		"team_edit_mode_owner.cleanup_intent",
		"func _commit_team_edit_cleanup",
		"team_edit_mode_owner.commit_cleanup",
		"_commit_team_edit_mode_enter(nav_reason, payload)",
		"_commit_team_edit_mode_exit(reason, payload)",
		"_cleanup_unit_edit_page_runtime(reason, payload)",
		"var show_intent := _team_edit_mode_show_intent(preloaded, loading_queued, false)",
		"var show_intent := _team_edit_mode_show_intent(preloaded, loading_queued, true)",
		"var cleanup_intent := _team_edit_cleanup_intent(reason, payload)",
		"_commit_team_edit_cleanup(cleanup_intent)",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing TeamEditMode wiring token: %s" % token)
			return
	var mode = TeamEditModeScript.new()
	if mode.mode_key() != "team_edit":
		_fail("TeamEditMode mode_key mismatch: %s" % mode.mode_key())
		return
	var show_fresh: Dictionary = mode.show_intent(false, false, false)
	if String(show_fresh.get("reason", "")) != "teamedit" or bool(show_fresh.get("preserve_canvas", true)) or not bool(show_fresh.get("reset_working_canvas", false)):
		_fail("TeamEditMode fresh show_intent mismatch: %s" % str(show_fresh))
		return
	var show_preserve: Dictionary = mode.show_intent(true, false, true)
	if String(show_preserve.get("reason", "")) != "teamedit_preserve" or not bool(show_preserve.get("preserve_canvas", false)) or bool(show_preserve.get("reset_working_canvas", true)):
		_fail("TeamEditMode preserve show_intent mismatch: %s" % str(show_preserve))
		return
	var show_wait: Dictionary = mode.show_intent(false, true, false)
	if bool(show_wait.get("should_apply", true)) or not bool(show_wait.get("loading_queued", false)):
		_fail("TeamEditMode queued show_intent mismatch: %s" % str(show_wait))
		return
	var enter_intent: Dictionary = mode.enter_intent("teamedit", {"preserve_canvas": false})
	if not mode.commit_enter(enter_intent) or mode.enter_count != 1:
		_fail("TeamEditMode commit_enter failed.")
		return
	var enter_trimmed: Dictionary = mode.enter_intent("  teamedit  ", {"preserve_canvas": false})
	if String(enter_trimmed.get("reason", "")) != "teamedit":
		_fail("TeamEditMode enter_intent should normalize reason: %s" % str(enter_trimmed))
		return
	if mode.commit_enter({"mode_key": "menu"}):
		_fail("TeamEditMode should reject wrong-mode enter commits.")
		return
	var cleanup_intent: Dictionary = mode.cleanup_intent("navigate", {"preserve_canvas": false})
	for key in ["clear_hover_cards", "close_detail_panels", "clear_bindings", "clear_drag_state", "clear_placement_state", "clear_clipboard", "clear_preview_caches", "reset_last_mouse"]:
		if not bool(cleanup_intent.get(key, false)):
			_fail("TeamEditMode cleanup_intent missing flag %s: %s" % [key, str(cleanup_intent)])
			return
	if not mode.commit_cleanup(cleanup_intent) or String(mode.last_cleanup_context.get("reason", "")) != "navigate":
		_fail("TeamEditMode commit_cleanup failed.")
		return
	var cleanup_trimmed: Dictionary = mode.cleanup_intent("  navigate  ", {"preserve_canvas": false})
	if String(cleanup_trimmed.get("reason", "")) != "navigate":
		_fail("TeamEditMode cleanup_intent should normalize reason: %s" % str(cleanup_trimmed))
		return
	var exit_intent: Dictionary = mode.exit_intent("navigate")
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("TeamEditMode commit_exit failed.")
		return
	var exit_trimmed: Dictionary = mode.exit_intent("  navigate  ")
	if String(exit_trimmed.get("reason", "")) != "navigate":
		_fail("TeamEditMode exit_intent should normalize reason: %s" % str(exit_trimmed))
		return
	print("TEAM_EDIT_MODE_CONTRACT_PROBE ok")
	quit(0)
