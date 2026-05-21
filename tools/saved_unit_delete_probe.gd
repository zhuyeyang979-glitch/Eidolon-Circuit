extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _write_unit(path: String, unit_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saved_units"))
	var payload := {
		"schema_version": "embedded_joint_unit_v2",
		"unit_id": unit_name,
		"unit_name": unit_name,
		"unit_role": "hero",
		"blueprint": {
			"role": "hero",
			"name": unit_name,
			"unit_name": unit_name,
			"blank_canvas": true,
			"custom_topology": {"nodes": [], "edges": []},
		},
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not create test saved unit: %s" % path)
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _init() -> void:
	var path_a := "user://saved_units/delete_probe_a.json"
	var path_b := "user://saved_units/delete_probe_b.json"
	_write_unit(path_a, "DELETE_PROBE_A")
	_write_unit(path_b, "DELETE_PROBE_B")
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_saved_units_library()
	main.saved_unit_selected_paths = [path_a, path_b]
	main._request_delete_saved_units()
	if main.saved_unit_pending_delete_paths.size() != 2:
		_fail("Delete request did not collect selected saved units.")
		return
	if main.saved_unit_delete_panel == null or not main.saved_unit_delete_panel.visible:
		_fail("Delete confirmation panel did not appear.")
		return
	main._confirm_delete_saved_units()
	if FileAccess.file_exists(path_a) or FileAccess.file_exists(path_b):
		_fail("Saved unit files still exist after confirm delete.")
		return
	if not main.saved_unit_pending_delete_paths.is_empty():
		_fail("Pending delete paths were not cleared.")
		return
	print("SAVED_UNIT_DELETE_PROBE deleted=2")
	quit()
