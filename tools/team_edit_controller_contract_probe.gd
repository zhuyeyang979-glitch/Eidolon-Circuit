extends SceneTree

const CONTROLLER_PATH := "res://scripts/controllers/team_edit_controller.gd"
const MAIN_PATH := "res://scripts/main.gd"
const TeamEditControllerScript := preload("res://scripts/controllers/team_edit_controller.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _init() -> void:
	if not FileAccess.file_exists(CONTROLLER_PATH):
		_fail("Missing TeamEditController script.")
	var controller_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(CONTROLLER_PATH))
	for token in [
		"class_name TeamEditController",
		"save_blocking_feedback",
		"action_key",
		"action_hint",
		"field_path",
	]:
		if controller_source.find(token) < 0:
			_fail("TeamEditController missing token: %s" % token)
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const TeamEditController = preload(\"res://scripts/controllers/team_edit_controller.gd\")",
		"var team_edit_controller: TeamEditController",
		"team_edit_controller = TeamEditController.new()",
		"team_edit_controller.save_blocking_feedback",
		"_save_unit_blocking_feedback",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate TeamEdit save-feedback token: %s" % token)
	var controller = TeamEditControllerScript.new()
	if controller.has_method("save_blocking_feedback"):
		_assert_feedback(
			controller.save_blocking_feedback("legacy drive/pointer field at $.blueprint.power", false),
			"remove_legacy_field",
			"$.blueprint.power",
			["legacy drive/pointer field", "power", "remove"]
		)
		_assert_feedback(
			controller.save_blocking_feedback("blueprint missing current custom topology", false),
			"rebuild_topology",
			"",
			["custom topology", "canvas"]
		)
		_assert_feedback(
			controller.save_blocking_feedback("cannot write to unit library", false),
			"check_write_access",
			"",
			["cannot write", "folder"]
		)
		_assert_feedback(
			controller.save_blocking_feedback("", true),
			"unknown",
			"",
			["unknown validation failure"]
		)
	else:
		_fail("TeamEditController missing save_blocking_feedback API.")
	if failed:
		quit(1)
		return
	print("TEAM_EDIT_CONTROLLER_CONTRACT_PROBE ok")
	quit(0)


func _assert_feedback(feedback: Dictionary, expected_action_key: String, expected_field_path: String, required_terms: Array) -> void:
	if String(feedback.get("action_key", "")) != expected_action_key:
		_fail("Expected action_key %s, got %s in %s." % [expected_action_key, String(feedback.get("action_key", "")), str(feedback)])
	if String(feedback.get("field_path", "")) != expected_field_path:
		_fail("Expected field_path %s, got %s in %s." % [expected_field_path, String(feedback.get("field_path", "")), str(feedback)])
	var summary := String(feedback.get("summary", ""))
	var reason := String(feedback.get("reason", ""))
	var action_hint := String(feedback.get("action_hint", ""))
	var joined := "%s %s %s" % [reason, action_hint, summary]
	for raw_term in required_terms:
		var term := String(raw_term)
		if joined.find(term) < 0:
			_fail("Feedback missing term %s in %s." % [term, str(feedback)])
