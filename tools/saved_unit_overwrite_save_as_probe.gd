extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _count_saved_units_named(main, unit_name: String) -> int:
	main._ensure_saved_unit_library_cache(true, true)
	var count := 0
	for raw_entry in main._unit_library_entries():
		if raw_entry is Dictionary and String(Dictionary(raw_entry).get("unit_name", "")) == unit_name:
			count += 1
	return count


func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)

	var unit_name := "Probe Save Overwrite %d" % int(Time.get_unix_time_from_system())
	var first_path := "user://saved_units/probe_save_overwrite_source.json"
	_remove_user_file(first_path)

	var bp := LegalStarterBlueprintFixture.build(main, unit_name)
	if bp.is_empty():
		_fail("Could not build legal save fixture.")
		return
	bp["probe_save_marker"] = "first"
	main.editor_working_blueprint = bp
	main.editor_working_role_key = "hero"
	main.editor_canvas_mode = "blank"
	var saved_path := main._save_editor_current_unit_to_library_named(unit_name, first_path)
	if saved_path != first_path:
		_fail("Initial explicit save should use requested path.")
		return
	var entry := main._unit_library_entry_from_file(first_path)
	if entry.is_empty():
		_fail("Initial save file could not be read back.")
		return
	if not main._load_saved_unit_entry_into_unit_editor(entry):
		_fail("Saved unit should load into Unit Edit.")
		return

	var loaded: Dictionary = main._editor_current_blueprint()
	loaded["probe_save_marker"] = "overwrite"
	var count_before := _count_saved_units_named(main, unit_name)
	var overwrite_path := main._save_editor_current_unit_to_library_named(unit_name)
	if overwrite_path != first_path:
		_fail("Save should overwrite the source path, got %s." % overwrite_path)
		return
	var count_after := _count_saved_units_named(main, unit_name)
	if count_after != count_before:
		_fail("Overwrite save should not create another same-name unit.")
		return
	var overwritten := main._unit_library_entry_from_file(first_path)
	var overwritten_bp: Dictionary = Dictionary(overwritten.get("blueprint", {}))
	if String(overwritten_bp.get("probe_save_marker", "")) != "overwrite":
		_fail("Overwrite did not update the original saved unit payload.")
		return

	var save_as_path := main._save_editor_current_unit_to_library_named(unit_name, "", true)
	if save_as_path == "" or save_as_path == first_path:
		_fail("Save As should create a distinct saved unit path.")
		return
	if not FileAccess.file_exists(save_as_path):
		_fail("Save As path does not exist.")
		return
	_remove_user_file(first_path)
	_remove_user_file(save_as_path)
	main._invalidate_saved_unit_library_cache()
	print("SAVED_UNIT_OVERWRITE_SAVE_AS_PROBE ok overwrite=%s save_as=%s" % [overwrite_path, save_as_path])
	quit()
