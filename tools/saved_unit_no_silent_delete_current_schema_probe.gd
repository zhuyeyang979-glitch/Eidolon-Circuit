extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entry_exists(main: Node, path: String) -> bool:
	for raw_entry in main._unit_library_entries():
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("path", "")) == path:
			return true
	return false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._ensure_saved_units_dir()
	var path := "%s/current_invalid_probe_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_ticks_msec())]
	var payload := {
		"schema_version": MainScene.SAVED_UNIT_SCHEMA_VERSION,
		"unit_id": "current-invalid-probe",
		"unit_name": "Current Invalid Probe",
		"unit_role": "hero",
		"blueprint": {
			"schema_version": MainScene.SAVED_UNIT_SCHEMA_VERSION,
			"role": "hero",
			"unit_name": "Current Invalid Probe",
			"name": "Current Invalid Probe",
			"custom_topology": {"nodes": [], "edges": []},
		},
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not write current invalid probe file.")
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	main._invalidate_saved_unit_library_cache()
	main._show_saved_units_library()
	if not FileAccess.file_exists(path):
		_fail("Current-schema invalid saved unit should not be silently deleted during normal list scan.")
		return
	if _entry_exists(main, path):
		_fail("Current-schema invalid saved unit should not appear as a valid library entry.")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SAVED_UNIT_NO_SILENT_DELETE_CURRENT_SCHEMA_PROBE ok path=%s" % path)
	quit(0)
