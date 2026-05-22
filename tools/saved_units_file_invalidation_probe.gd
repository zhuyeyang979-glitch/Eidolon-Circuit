extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _has_entry_path(main: Node, path: String) -> bool:
	for raw_entry in main._unit_library_entries():
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("path", "")) == path:
			return true
	return false


func _write_probe_unit(path: String, unit_name: String) -> void:
	var payload := {
		"schema_version": "embedded_joint_unit_v2",
		"unit_id": "cache-probe",
		"unit_name": unit_name,
		"unit_role": "hero",
		"team_color": "#53d6ff",
		"blueprint": {
			"schema_version": "embedded_joint_unit_v2",
			"unit_name": unit_name,
			"name": unit_name,
			"role": "hero",
			"custom_topology": {"nodes": [], "edges": []},
			"module_bindings": [],
		},
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not create temporary saved unit file.")
	file.store_string(JSON.stringify(payload))
	file.close()


func _init() -> void:
	var main := MainScene.new()
	root.add_child(main)
	main._ready()
	main._ensure_saved_units_dir()
	var temp_path := "%s/cache_probe_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_unix_time_from_system())]
	_write_probe_unit(temp_path, "Cache Probe Unit")
	main._show_saved_units_library()
	if not _has_entry_path(main, temp_path):
		_fail("Saved unit cache should pick up newly created files when entering the page.")
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	if remove_error != OK:
		_fail("Could not remove temporary saved unit file: %d" % remove_error)
	main._show_saved_units_library()
	if _has_entry_path(main, temp_path):
		_fail("Saved unit cache should drop deleted files after disk invalidation.")
	print("SAVED_UNITS_FILE_INVALIDATION_PROBE ok")
	quit()
