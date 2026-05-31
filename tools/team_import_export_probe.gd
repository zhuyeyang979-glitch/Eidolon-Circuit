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
	var empty_export := main._export_editor_team(empty_path)
	if empty_export == "" or not FileAccess.file_exists(empty_path):
		_fail("Could not export an empty Team Match roster.")
	if not main._import_editor_team(empty_path):
		_fail("Could not import the exported empty roster.")
	var empty_summary: Dictionary = main._team_summary(1)
	if int(empty_summary.get("units", -1)) != 0 or int(empty_summary.get("cost", -1)) != 0:
		_fail("Empty roster import did not round-trip as empty.")
	main._legalize_ai_player_roster(1, true)
	var filled_summary: Dictionary = main._team_summary(1)
	if int(filled_summary.get("units", 0)) != MainScene.ROSTER_UNIT_CAP:
		_fail("Probe setup did not create a ten-unit roster.")
	var filled_path := "user://saved_teams/probe_filled_team.json"
	var filled_export := main._export_editor_team(filled_path)
	if filled_export == "" or not FileAccess.file_exists(filled_path):
		_fail("Could not export a filled Team Match roster.")
	main._clear_editor_team()
	if int(main._team_summary(1).get("units", -1)) != 0:
		_fail("Clear team did not empty the roster before import.")
	if not main._import_editor_team(filled_path):
		_fail("Could not import the exported filled roster.")
	var imported_summary: Dictionary = main._team_summary(1)
	if int(imported_summary.get("units", 0)) != MainScene.ROSTER_UNIT_CAP:
		_fail("Filled roster import did not restore ten units.")
	if int(imported_summary.get("cost", 0)) != int(filled_summary.get("cost", -1)):
		_fail("Filled roster import changed the team cost.")
	print("TEAM_IMPORT_EXPORT_PROBE empty_cost=%d filled_units=%d filled_cost=%d imported_cost=%d" % [
		int(empty_summary.get("cost", -1)),
		int(filled_summary.get("units", -1)),
		int(filled_summary.get("cost", -1)),
		int(imported_summary.get("cost", -1)),
	])
	quit()
