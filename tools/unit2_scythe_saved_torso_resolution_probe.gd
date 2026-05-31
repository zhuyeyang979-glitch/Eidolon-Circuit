extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit2_path() -> String:
	var dir := DirAccess.open("user://saved_units")
	if dir == null:
		return ""
	var best_path := ""
	var best_time := -1
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := "user://saved_units/%s" % file_name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			continue
		var data: Dictionary = parsed
		if String(data.get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_unit2_path()
	if path == "":
		_fail("No saved unit named 2 found.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Could not open latest Unit 2 file: %s." % path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved Unit 2 JSON is invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var role_key := String(saved.get("unit_role", "hero"))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var topology: Dictionary = Dictionary(unit_bp.get("custom_topology", {}))
	var nodes: Array = Array(topology.get("nodes", []))
	if nodes.is_empty() or not (nodes[0] is Dictionary):
		_fail("Saved Unit 2 has no topology node 0.")
		return
	var node0: Dictionary = Dictionary(nodes[0])
	var torso_part: Dictionary = main._topology_node_part(role_key, node0, unit_bp)
	if not main._component_is_torso(torso_part):
		_fail("Unit 2 node 0 should resolve as torso, got %s from part_name=%s component_name=%s." % [
			String(torso_part.get("name", "")),
			String(node0.get("part_name", "")),
			String(node0.get("component_name", "")),
		])
		return
	var note := main._training_blueprint_illegal_note(1, role_key, unit_bp)
	if note != "":
		_fail("Unit 2 should be legal after torso resolution, got: %s" % note)
		return
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint(role_key, unit_bp)
	var side_mount_binding_found := false
	for raw_binding in runtime_bindings:
		if not (raw_binding is Dictionary):
			continue
		var binding: Dictionary = raw_binding
		if bool(binding.get("runtime_valid", true)) and String(binding.get("side_mount_action_side", "")) != "" and int(binding.get("side_mount_action_node", -1)) >= 0:
			side_mount_binding_found = true
			break
	if not side_mount_binding_found:
		_fail("Unit 2 torso resolved, but no valid side-mounted scythe runtime binding was found.")
		return
	print("UNIT2_SCYTHE_SAVED_TORSO_RESOLUTION_PROBE ok path=%s torso=%s bindings=%d" % [
		ProjectSettings.globalize_path(path),
		String(torso_part.get("name", "")),
		runtime_bindings.size(),
	])
	quit()
