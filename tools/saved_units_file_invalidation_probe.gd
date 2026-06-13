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


func _write_probe_unit(main: Node, path: String, unit_name: String) -> void:
	var blueprint: Dictionary = main._ai_starter_unit(unit_name)
	blueprint["schema_version"] = MainScene.SAVED_UNIT_SCHEMA_VERSION
	blueprint["unit_name"] = unit_name
	blueprint["name"] = unit_name
	var payload := {
		"schema_version": MainScene.SAVED_UNIT_SCHEMA_VERSION,
		"unit_id": "cache-probe",
		"unit_name": unit_name,
		"unit_role": "hero",
		"team_color": blueprint.get("team_color", {}),
		"blueprint": main._json_safe_value(blueprint),
	}
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not create temporary saved unit file.")
	file.store_string(JSON.stringify(payload))
	file.close()


func _init() -> void:
	var main := MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._ensure_saved_units_dir()
	var temp_path := "%s/cache_probe_%d.json" % [MainScene.SAVED_UNITS_DIR, int(Time.get_unix_time_from_system())]
	_write_probe_unit(main, temp_path, "Cache Probe Unit")
	main._show_saved_units_library()
	if not _has_entry_path(main, temp_path):
		_fail("Saved unit cache should pick up newly created files when entering the page.")
	main._show_saved_units_library(temp_path)
	if main.saved_unit_selected_index < 0:
		_fail("Focused saved-unit library open should select the newly saved unit.")
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	if remove_error != OK:
		_fail("Could not remove temporary saved unit file: %d" % remove_error)
	main._show_saved_units_library(temp_path)
	if main.saved_unit_selected_index != -1 or main.saved_unit_detail_path != "":
		_fail("Missing focused saved-unit file should clear stale selection/detail state.")
	var missing_hint := String(main.saved_unit_hint_label.text) if main.saved_unit_hint_label != null else ""
	if not missing_hint.contains("不存在") and not missing_hint.contains("gone"):
		_fail("Missing focused saved-unit file should explain that the file is gone.")
	main._show_saved_units_library()
	if _has_entry_path(main, temp_path):
		_fail("Saved unit cache should drop deleted files after disk invalidation.")
	print("SAVED_UNITS_FILE_INVALIDATION_PROBE ok")
	quit()
