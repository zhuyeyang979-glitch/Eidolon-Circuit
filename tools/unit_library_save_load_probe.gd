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
	if not main._editor_is_blank_work_canvas():
		_fail("TeamEdit should open on a temporary blank unit canvas.")
	var bp: Dictionary = main._editor_current_blueprint()
	bp["custom_topology"] = main._default_free_canvas_topology("hero")
	bp["blank_canvas"] = false
	bp["unit_name"] = "Probe Unit"
	var path := "user://saved_units/probe_unit_library.json"
	var saved_path := main._save_editor_current_unit_to_library(path)
	if saved_path == "":
		_fail("Unit library save returned an empty path.")
	var found := false
	var saved_entry := {}
	for entry in main._unit_library_entries():
		if String(Dictionary(entry).get("path", "")) == path:
			found = true
			saved_entry = Dictionary(entry)
			break
	if not found:
		_fail("Saved unit was not visible in unit library entries.")
	if not (saved_entry.get("blueprint", {}) is Dictionary):
		_fail("Saved unit entry did not include a blueprint.")
	main._load_unit_library_entry_to_canvas(saved_entry)
	var loaded: Dictionary = main._editor_current_blueprint()
	if String(loaded.get("unit_name", "")) != "Probe Unit":
		_fail("Loaded unit name mismatch.")
	if Dictionary(loaded.get("entry_pose", {})).is_empty():
		_fail("Saved unit should carry entry_pose data.")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("UNIT_LIBRARY_SAVE_LOAD_PROBE ok path=%s nodes=%d" % [path, Array(Dictionary(loaded.get("custom_topology", {})).get("nodes", [])).size()])
	quit()
