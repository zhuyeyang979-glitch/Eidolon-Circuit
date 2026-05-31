extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write probe JSON: %s" % path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._ensure_saved_units_dir()
	main._ensure_saved_teams_dir()
	var unit_path := "%s/legacy_power_probe_unit.json" % MainScene.SAVED_UNITS_DIR
	var team_path := "%s/legacy_power_probe_team.json" % MainScene.SAVED_TEAMS_DIR
	var old_unit := {
		"schema_version": "embedded_joint_unit_v2",
		"blueprint": {"schema_version": "embedded_joint_unit_v2", "engine_power": 12.0},
	}
	var old_team := {
		"schema_version": 1,
		"slots": [{"blueprint": {"schema_version": "embedded_joint_unit_v2", "required_power": 2.0}}],
	}
	_write_json(unit_path, old_unit)
	_write_json(team_path, old_team)
	main._purge_legacy_saved_units(true)
	main._purge_legacy_saved_teams(true)
	if FileAccess.file_exists(unit_path):
		_fail("Legacy saved unit was not deleted.")
		return
	if FileAccess.file_exists(team_path):
		_fail("Legacy saved team was not deleted.")
		return
	print("SAVED_DATA_PURGE_PROBE ok")
	quit()
