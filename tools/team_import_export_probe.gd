extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var empty_path := "user://saved_teams/probe_empty_team.json"
	if FileAccess.file_exists(empty_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(empty_path))
	var empty_export := main._export_editor_team(empty_path)
	if empty_export != "" or FileAccess.file_exists(empty_path):
		_fail("Incomplete TeamEdit roster should not export as a formal team.")
		return
	var empty_summary: Dictionary = main._team_summary(1)
	if int(empty_summary.get("units", -1)) != 0:
		_fail("Rejected empty export should not mutate the roster.")
		return
	main._legalize_ai_player_roster(1, true)
	var filled_summary: Dictionary = main._team_summary(1)
	if int(filled_summary.get("units", 0)) != 5:
		_fail("Probe setup did not create a five-unit roster.")
		return
	var filled_path := "user://saved_teams/probe_filled_team.json"
	if FileAccess.file_exists(filled_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(filled_path))
	var filled_export := main._export_editor_team(filled_path)
	if filled_export == "" or not FileAccess.file_exists(filled_path):
		_fail("Could not export a filled Team Match roster.")
		return
	var payload = JSON.parse_string(FileAccess.get_file_as_string(filled_path))
	if not (payload is Dictionary) or String(Dictionary(payload).get("rule_id", "")) != "light_5_pick_3_v1":
		_fail("Exported team should persist the active rule_id.")
		return
	main._clear_editor_team()
	if int(main._team_summary(1).get("units", -1)) != 0:
		_fail("Clear team did not empty the roster before import.")
		return
	if not main._import_editor_team(filled_path):
		_fail("Could not import the exported filled roster.")
		return
	var imported_summary: Dictionary = main._team_summary(1)
	if int(imported_summary.get("units", 0)) != 5:
		_fail("Filled roster import did not restore five units.")
		return
	if int(imported_summary.get("cost", 0)) != int(filled_summary.get("cost", -1)):
		_fail("Filled roster import changed the team cost.")
		return
	var partial_path := "user://saved_teams/probe_partial_light_team.json"
	var partial_payload := {
		"schema_version": MainScene.SAVED_TEAM_SCHEMA_VERSION,
		"rule_id": "light_5_pick_3_v1",
		"match_format": "light",
		"roster_cap": 5,
		"sortie_cap": 3,
		"slots": [
			{"empty": true},
			{"empty": true},
			{"empty": true},
			{"empty": true},
			{"empty": true},
		],
	}
	var partial_file := FileAccess.open(partial_path, FileAccess.WRITE)
	partial_file.store_string(JSON.stringify(partial_payload, "\t"))
	partial_file.close()
	if main._import_editor_team(partial_path):
		_fail("Incomplete light team file should fail import re-audit.")
		return
	if not FileAccess.file_exists(partial_path) or main._roster_unit_total(1) != 5:
		_fail("Rejected partial import should preserve both file and current roster.")
		return
	var unsupported_path := "user://saved_teams/probe_unsupported_10_pick_6.json"
	var unsupported_payload := partial_payload.duplicate(true)
	unsupported_payload.erase("rule_id")
	unsupported_payload["match_format"] = "standard"
	unsupported_payload["roster_cap"] = 10
	unsupported_payload["sortie_cap"] = 6
	unsupported_payload["slots"] = []
	for _i in range(10):
		unsupported_payload["slots"].append({"empty": true})
	var unsupported_file := FileAccess.open(unsupported_path, FileAccess.WRITE)
	unsupported_file.store_string(JSON.stringify(unsupported_payload, "\t"))
	unsupported_file.close()
	if main._import_editor_team(unsupported_path):
		_fail("Unsupported 10/6 team file should fail import.")
		return
	if not FileAccess.file_exists(unsupported_path) or main._roster_unit_total(1) != 5:
		_fail("Rejected unsupported import should preserve both file and current roster.")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(filled_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(partial_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(unsupported_path))
	print("TEAM_IMPORT_EXPORT_PROBE empty_cost=%d filled_units=%d filled_cost=%d imported_cost=%d" % [
		int(empty_summary.get("cost", -1)),
		int(filled_summary.get("units", -1)),
		int(filled_summary.get("cost", -1)),
		int(imported_summary.get("cost", -1)),
	])
	quit()
