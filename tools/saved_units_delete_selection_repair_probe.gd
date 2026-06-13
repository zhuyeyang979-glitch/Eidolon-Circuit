extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _entry_index_for_path(main: Node, path: String) -> int:
	var entries: Array = main._saved_unit_filtered_entries()
	for i in range(entries.size()):
		if entries[i] is Dictionary and String(Dictionary(entries[i]).get("path", "")) == path:
			return i
	return -1


func _entry_exists(main: Node, path: String) -> bool:
	return _entry_index_for_path(main, path) >= 0


func _write_probe_unit(main: Node, path: String, unit_name: String) -> void:
	var blueprint: Dictionary = main._ai_starter_unit(unit_name)
	blueprint["schema_version"] = MainScene.SAVED_UNIT_SCHEMA_VERSION
	blueprint["unit_name"] = unit_name
	blueprint["name"] = unit_name
	var payload := {
		"schema_version": MainScene.SAVED_UNIT_SCHEMA_VERSION,
		"unit_id": "%s-id" % unit_name.to_snake_case(),
		"unit_name": unit_name,
		"unit_role": "hero",
		"team_color": blueprint.get("team_color", {}),
		"blueprint": main._json_safe_value(blueprint),
	}
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not create temporary saved unit file: %s" % path)
	file.store_string(JSON.stringify(payload))
	file.close()


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._ensure_saved_units_dir()
	var stamp := int(Time.get_ticks_msec())
	var path_a := "%s/delete_repair_a_%d.json" % [MainScene.SAVED_UNITS_DIR, stamp]
	var path_b := "%s/delete_repair_b_%d.json" % [MainScene.SAVED_UNITS_DIR, stamp]
	_write_probe_unit(main, path_a, "Delete Repair A")
	_write_probe_unit(main, path_b, "Delete Repair B")
	main._show_saved_units_library(path_a)
	var index_a := _entry_index_for_path(main, path_a)
	if index_a < 0 or not _entry_exists(main, path_b):
		_fail("Probe saved units did not enter the library.")
	main.saved_unit_selected_index = index_a
	main.saved_unit_page = int(floor(float(index_a) / float(maxi(1, main.saved_unit_buttons.size()))))
	main.saved_unit_pending_delete_paths = [path_a]
	main._confirm_delete_saved_units()
	if _entry_exists(main, path_a):
		_fail("Confirmed delete should remove the selected saved unit.")
	if not _entry_exists(main, path_b):
		_fail("Confirmed delete should leave unrelated saved units in the library.")
	if main.saved_unit_selected_index < 0:
		_fail("Post-delete selection repair should keep a remaining unit selected.")
	var selected_entry: Dictionary = main._saved_unit_entry_at_absolute_index(main.saved_unit_selected_index)
	if selected_entry.is_empty() or String(selected_entry.get("path", "")) == path_a:
		_fail("Post-delete selection should point at a remaining saved unit.")
	if main.saved_unit_detail_path != String(selected_entry.get("path", "")):
		_fail("Post-delete detail should follow the repaired selection.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path_b))
	print("SAVED_UNITS_DELETE_SELECTION_REPAIR_PROBE ok selected=%s" % String(selected_entry.get("path", "")))
	quit(0)
