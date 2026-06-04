extends SceneTree

const MODE_PATH := "res://scripts/modes/settings_mode.gd"
const MAIN_PATH := "res://scripts/main.gd"
const SettingsModeScript := preload("res://scripts/modes/settings_mode.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(MODE_PATH):
		_fail("Missing SettingsMode script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MODE_PATH))
	for token in [
		"class_name SettingsMode",
		"MODE_KEY := \"settings\"",
		"func bind",
		"func show_intent",
		"func enter_intent",
		"func commit_enter",
		"func category_intent",
		"func commit_category",
		"func exit_intent",
		"func commit_exit",
	]:
		if source.find(token) < 0:
			_fail("SettingsMode missing token: %s" % token)
			return
	for forbidden in ["Input.", "InputMap.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "_rebuild_settings_list", "_handle_battle_input_rebind_event"]:
		if source.find(forbidden) >= 0:
			_fail("SettingsMode should stay settings-boundary only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const SettingsMode = preload(\"res://scripts/modes/settings_mode.gd\")",
		"var settings_mode_owner: SettingsMode",
		"settings_mode_owner = SettingsMode.new()",
		"settings_mode_owner.bind(self, settings_controller)",
		"func _commit_settings_mode_enter",
		"func _commit_settings_mode_exit",
		"settings_mode_owner.enter_intent",
		"settings_mode_owner.commit_enter",
		"settings_mode_owner.exit_intent",
		"settings_mode_owner.commit_exit",
		"func _settings_mode_show_intent",
		"settings_mode_owner.show_intent",
		"func _settings_category_intent",
		"settings_mode_owner.category_intent",
		"func _apply_settings_category_intent",
		"settings_mode_owner.commit_category",
		"_commit_settings_mode_enter(nav_reason, payload)",
		"_commit_settings_mode_exit(reason, payload)",
		"var show_intent := _settings_mode_show_intent(category_key, preloaded, resolved_return_target, loading_queued)",
		"settings_category = String(show_intent.get(\"category_key\", category_key))",
		"_apply_settings_category_intent(_settings_category_intent(category_key))",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing SettingsMode wiring token: %s" % token)
			return
	var mode = SettingsModeScript.new()
	if mode.mode_key() != "settings":
		_fail("SettingsMode mode_key mismatch: %s" % mode.mode_key())
		return
	var show_wait: Dictionary = mode.show_intent("", false, "menu", true)
	if String(show_wait.get("category_key", "")) != "root" or bool(show_wait.get("should_apply", true)) or not bool(show_wait.get("loading_queued", false)):
		_fail("SettingsMode queued show_intent mismatch: %s" % str(show_wait))
		return
	var show_now: Dictionary = mode.show_intent("input", true, "battle", false)
	if String(show_now.get("category_key", "")) != "input" or not bool(show_now.get("should_apply", false)) or String(show_now.get("return_target", "")) != "battle":
		_fail("SettingsMode apply show_intent mismatch: %s" % str(show_now))
		return
	var enter_intent: Dictionary = mode.enter_intent("settings", {"category": "input"})
	if not mode.commit_enter(enter_intent) or mode.enter_count != 1:
		_fail("SettingsMode commit_enter failed.")
		return
	if mode.commit_enter({"mode_key": "menu"}):
		_fail("SettingsMode should reject wrong-mode enter commits.")
		return
	var category_intent: Dictionary = mode.category_intent("video")
	if String(category_intent.get("category_key", "")) != "video" or not bool(category_intent.get("reset_index", false)) or not bool(category_intent.get("clear_rebind", false)):
		_fail("SettingsMode category_intent mismatch: %s" % str(category_intent))
		return
	if not mode.commit_category(category_intent) or String(mode.last_category_context.get("category_key", "")) != "video":
		_fail("SettingsMode commit_category failed.")
		return
	var root_category: Dictionary = mode.category_intent("")
	if String(root_category.get("category_key", "")) != "root":
		_fail("SettingsMode empty category should resolve to root: %s" % str(root_category))
		return
	var exit_intent: Dictionary = mode.exit_intent("navigate")
	if not mode.commit_exit(exit_intent) or mode.exit_count != 1:
		_fail("SettingsMode commit_exit failed.")
		return
	print("SETTINGS_MODE_CONTRACT_PROBE ok")
	quit(0)
