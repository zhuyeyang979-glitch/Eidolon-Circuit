extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _saved_entries_from_roster(main, player_id: int) -> Array:
	var entries: Array = []
	for raw_entry in main._all_roster_order(player_id):
		var roster_entry: Dictionary = raw_entry
		var role_key := String(roster_entry.get("role", "hero"))
		var unit_index := int(roster_entry.get("index", 0))
		var bp: Dictionary = main._blueprint_for(player_id, role_key, unit_index).duplicate(true)
		var unit_name := "Probe %s %d" % [role_key, unit_index]
		bp["unit_name"] = unit_name
		entries.append({
			"unit_library": true,
			"path": "probe://saved-team/%s/%d" % [role_key, unit_index],
			"role": role_key,
			"blueprint": bp,
			"unit_name": unit_name,
		})
	return entries


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._legalize_ai_player_roster(1, true)
	var selected := _saved_entries_from_roster(main, 1)
	if selected.size() != 5:
		_fail("Probe should build exactly five saved-unit entries.")
		return
	var team_path: String = main._save_team_from_saved_unit_selection("Probe Saved Team", selected)
	if team_path == "":
		_fail("Failed to save team from selected saved units.")
		return
	var teams := main._saved_teams_entries(true)
	var found := false
	for raw_team in teams:
		if raw_team is Dictionary and String(Dictionary(raw_team).get("path", "")) == team_path:
			found = true
			break
	if not found:
		_fail("Saved team should appear in saved team entries.")
		return
	if not main._load_saved_team_to_current_roster(team_path):
		_fail("Saved team should load into current roster.")
		return
	if main._roster_unit_total(1) != 5:
		_fail("Loaded saved team should restore exactly five units.")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(team_path))
	print("SAVED_UNITS_SAVED_TEAM_VIEW_PROBE ok path=%s" % team_path)
	quit()
