extends SceneTree

const HOST_PATH := "res://scripts/app/app_mode_host.gd"
const MAIN_PATH := "res://scripts/main.gd"
const AppModeHostScript := preload("res://scripts/app/app_mode_host.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(HOST_PATH):
		_fail("Missing AppModeHost script.")
		return
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(HOST_PATH))
	for token in [
		"class_name AppModeHost",
		"MODE_MENU",
		"MODE_TEAM_EDIT",
		"MODE_SAVED_UNITS",
		"MODE_TRAINING",
		"MODE_BATTLE",
		"MODE_SETTINGS",
		"mode_key_for_page",
		"transition_intent",
		"commit_transition",
		"reset",
	]:
		if source.find(token) < 0:
			_fail("AppModeHost missing token: %s" % token)
			return
	for forbidden in ["extends Node", "Input.", "FileAccess.open", "DirAccess", "JSON.parse_string", "Control.new", "Button", "active_units", "all_units"]:
		if source.find(forbidden) >= 0:
			_fail("AppModeHost should stay boundary-only; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const AppModeHost = preload(\"res://scripts/app/app_mode_host.gd\")",
		"var app_mode_host: AppModeHost",
		"app_mode_host = AppModeHost.new()",
		"app_mode_host.reset()",
		"_app_mode_key_for_page",
		"_commit_app_mode_for_page",
		"app_mode_host.mode_key_for_page",
		"app_mode_host.transition_intent",
		"app_mode_host.commit_transition",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd missing AppModeHost wiring token: %s" % token)
			return
	var host = AppModeHostScript.new()
	for mode_key in ["menu", "team_edit", "saved_units", "training", "battle", "settings"]:
		if not host.is_valid_mode_key(mode_key):
			_fail("AppModeHost missing valid mode: %s" % mode_key)
			return
	if host.is_valid_mode_key("scout"):
		_fail("AppModeHost should not invent a separate scout mode before ownership is decided.")
		return
	for page_case in [
		{"page": "menu", "mode": "menu"},
		{"page": "editor", "mode": "team_edit"},
		{"page": "saved_units", "mode": "saved_units"},
		{"page": "settings", "mode": "settings"},
		{"page": "battle", "mode": "battle"},
	]:
		var page := String(page_case.get("page", ""))
		var expected_mode := String(page_case.get("mode", ""))
		var resolved_mode := host.mode_key_for_page(page)
		if resolved_mode != expected_mode:
			_fail("AppModeHost page mode mismatch for %s: expected %s got %s" % [page, expected_mode, resolved_mode])
			return
	if host.mode_key_for_page("battle", {"mode": "training"}) != "training":
		_fail("Training battle page should resolve to training app mode.")
		return
	if host.mode_key_for_page(" battle ", {"mode": " training "}) != "training":
		_fail("Training battle page should normalize page and payload mode.")
		return
	if host.mode_key_for_page("scout", {"mode": "training"}) != "training":
		_fail("Training scout page should resolve to training app mode.")
		return
	if host.mode_key_for_page(" scout ", {"mode": " training "}) != "training":
		_fail("Training scout page should normalize page and payload mode.")
		return
	if host.mode_key_for_page("scout", {"mode": "ai"}) != "battle":
		_fail("AI scout page should resolve to battle app mode.")
		return
	if host.mode_key_for_page("scout") != "":
		_fail("Scout page without a payload mode should stay unmapped.")
		return
	var empty_intent: Dictionary = host.transition_intent("")
	if bool(empty_intent.get("accepted", true)) or String(empty_intent.get("reject_reason", "")) != "empty_mode_key":
		_fail("Empty transition should be rejected: %s" % str(empty_intent))
		return
	var unknown_intent: Dictionary = host.transition_intent("credits")
	if bool(unknown_intent.get("accepted", true)) or String(unknown_intent.get("reject_reason", "")) != "unknown_mode_key":
		_fail("Unknown transition should be rejected: %s" % str(unknown_intent))
		return
	var menu_intent: Dictionary = host.transition_intent("menu", "startup", {"boot": true})
	if not bool(menu_intent.get("accepted", false)) or bool(menu_intent.get("noop", true)):
		_fail("Menu transition should be accepted and non-noop: %s" % str(menu_intent))
		return
	var trimmed_battle_intent: Dictionary = host.transition_intent(" battle ", "  training_start  ", {"mode": " training "})
	if not bool(trimmed_battle_intent.get("accepted", false)) or String(trimmed_battle_intent.get("target_mode_key", "")) != "battle" or String(trimmed_battle_intent.get("request_reason", "")) != "training_start":
		_fail("Transition intent should normalize target mode and reason: %s" % str(trimmed_battle_intent))
		return
	if String(Dictionary(trimmed_battle_intent.get("payload", {})).get("mode", "")) != "training":
		_fail("Transition intent should normalize payload mode: %s" % str(trimmed_battle_intent))
		return
	if not host.commit_transition(menu_intent):
		_fail("Menu transition commit failed.")
		return
	if host.current_mode_key != "menu" or host.previous_mode_key != "" or host.transition_count != 1:
		_fail("Menu transition state mismatch: current=%s previous=%s count=%d" % [host.current_mode_key, host.previous_mode_key, host.transition_count])
		return
	var same_intent: Dictionary = host.transition_intent("menu", "repeat")
	if not bool(same_intent.get("noop", false)) or not host.commit_transition(same_intent) or host.transition_count != 1:
		_fail("Same-mode transition should be a committed noop.")
		return
	var battle_intent: Dictionary = host.transition_intent("battle", "training_start")
	if not host.commit_transition(battle_intent):
		_fail("Battle transition commit failed.")
		return
	if host.current_mode_key != "battle" or host.previous_mode_key != "menu" or host.transition_count != 2:
		_fail("Battle transition state mismatch: current=%s previous=%s count=%d" % [host.current_mode_key, host.previous_mode_key, host.transition_count])
		return
	if not host.reset("settings") or host.current_mode_key != "settings" or host.transition_count != 0:
		_fail("Reset should accept a valid initial mode.")
		return
	if host.reset("credits"):
		_fail("Reset should reject an invalid initial mode.")
		return
	print("APP_MODE_HOST_CONTRACT_PROBE ok transitions=2")
	quit(0)
