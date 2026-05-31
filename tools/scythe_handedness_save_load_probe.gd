extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main: Node) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _scythe_index(main: Node) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _build_unit(main: Node, unit_name: String) -> Dictionary:
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso: int = main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var scythe: int = main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LEFT SCYTHE", "muscle", _scythe_index(main), Vector2.RIGHT)
	var node: Dictionary = Dictionary(nodes[scythe]).duplicate(true)
	node["visual_handedness"] = "left"
	nodes[scythe] = node
	unit_bp["role"] = "hero"
	unit_bp["unit_name"] = unit_name
	unit_bp["blank_canvas"] = false
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	return unit_bp


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	var unit_name := "Scythe Handedness Save %d" % int(Time.get_ticks_msec())
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = _build_unit(main, unit_name)
	var path := main._save_editor_current_unit_to_library_named(unit_name, "", true)
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
		if raw_node is Dictionary and String(Dictionary(raw_node).get("visual_handedness", "")) == "left":
			found_left = true
			break
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not found_left:
		_fail("Loaded saved unit did not preserve left scythe handedness.")
		return
	print("SCYTHE_HANDEDNESS_SAVE_LOAD_PROBE ok path=%s" % path)
	quit()
