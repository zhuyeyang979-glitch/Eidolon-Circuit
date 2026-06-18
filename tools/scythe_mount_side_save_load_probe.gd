extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main := Helpers.setup_main(self)
	var unit_name := "Scythe Mount Side Save %d" % int(Time.get_ticks_msec())
	var setup := Helpers.build_torso_limb_scythe_module(main, "left")
	if setup.is_empty():
		_fail("Could not build scythe module test unit.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	if not Helpers.bind_scythe_action_side(main, unit_bp, int(setup.get("scythe", -1)), int(setup.get("module", -1)), "left", 1):
		_fail("Could not bind left scythe action.")
		return
	if not Helpers.make_scythe_module_deployable(main, setup):
		_fail("Could not install deployable scythe payloads.")
		return
	unit_bp = setup.get("unit_bp", {})
	unit_bp["unit_name"] = unit_name
	unit_bp["name"] = unit_name
	var legality_note: String = main._training_blueprint_illegal_note(1, "hero", unit_bp)
	if legality_note != "":
		_fail("Bound scythe save fixture should be legal: %s" % legality_note)
		return
	var path: String = main._save_editor_current_unit_to_library_named(unit_name, "", true)
	if path == "" or not FileAccess.file_exists(path):
		_fail("Save did not create a readable file.")
		return
	if not main._load_saved_unit_into_unit_editor(path):
		_fail("Saved scythe unit could not be loaded back into Unit Edit.")
		return
	var loaded: Dictionary = main._editor_current_blueprint()
	var nodes: Array = Dictionary(loaded.get("custom_topology", {})).get("nodes", [])
	var found_left := false
	for raw_node in nodes:
		if not (raw_node is Dictionary):
			continue
		var node: Dictionary = raw_node
		if String(node.get("visual_mount_side", "")) == "left" and String(node.get("orientation_category", "")) == "orthogonal_side_mount":
			found_left = true
			break
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not found_left:
		_fail("Loaded saved unit did not preserve left scythe mount side.")
		return
	print("SCYTHE_MOUNT_SIDE_SAVE_LOAD_PROBE ok path=%s" % path)
	quit()
