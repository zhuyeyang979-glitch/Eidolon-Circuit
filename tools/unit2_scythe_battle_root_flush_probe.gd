extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")
const Renderer := preload("res://scripts/assembly_board_renderer.gd")


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
		if String(Dictionary(parsed).get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _segment_for_node(segments: Array, node_index: int) -> Dictionary:
	for raw_segment in segments:
		if raw_segment is Dictionary and int(Dictionary(raw_segment).get("node_index", -9999)) == node_index:
			return Dictionary(raw_segment)
	return {}


func _edge_parent_for_node(edges: Array, child_index: int) -> int:
	for raw_edge in edges:
		if not (raw_edge is Dictionary):
			continue
		var edge: Dictionary = raw_edge
		var a := int(edge.get("a_node", edge.get("a", -1)))
		var b := int(edge.get("b_node", edge.get("b", -1)))
		var a_socket := String(edge.get("a_socket", ""))
		var b_socket := String(edge.get("b_socket", ""))
		if a == child_index and a_socket == "root_joint" and (b_socket == "distal" or b_socket.begins_with("torso_port:")):
			return b
		if b == child_index and b_socket == "root_joint" and (a_socket == "distal" or a_socket.begins_with("torso_port:")):
			return a
	return -1


func _assert_runtime_root_flush(segments: Array, edges: Array, scythe_node: int, label: String) -> void:
	var scythe := _segment_for_node(segments, scythe_node)
	if scythe.is_empty():
		_fail("%s scythe segment %d missing." % [label, scythe_node])
		return
	var parent_index := _edge_parent_for_node(edges, scythe_node)
	if parent_index < 0:
		_fail("%s scythe %d parent edge missing." % [label, scythe_node])
		return
	var parent := _segment_for_node(segments, parent_index)
	if parent.is_empty():
		_fail("%s parent segment %d missing." % [label, parent_index])
		return
	var actual: Vector2 = scythe.get("a", Vector2.ZERO)
	var expected: Vector2 = scythe.get("parent_socket_anchor", parent.get("b", actual))
	if String(parent.get("part_kind", "")) != "torso":
		expected = parent.get("b", expected)
	if actual.distance_to(expected) > 0.0005:
		_fail("%s scythe %d root detached from parent %d: %.6f." % [label, scythe_node, parent_index, actual.distance_to(expected)])
		return
	var axis: Vector2 = Vector2(scythe.get("b", actual)) - actual
	var node := Renderer.segment_to_component_node(scythe)
	var root_anchor := Renderer.component_connection_anchor((actual + Vector2(scythe.get("b", actual))) * 0.5, node, axis, float(scythe.get("radius", 0.025)), actual - axis, "root_joint", axis.length(), false)
	if root_anchor.distance_to(actual) > 0.0005:
		_fail("%s renderer root handle detached from resolved root: %.6f." % [label, root_anchor.distance_to(actual)])
		return


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
	var stats: Dictionary = main._compute_unit_stats(1, role_key, -1, unit_bp)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Unit2 Scythe Flush", "owner_id": 1, "role": role_key, "stats": stats})
	fighter.deploy(0.0, 0.0)
	var segments: Array = fighter._runtime_topology_world_segments(true, false)
	var edges: Array = Array(stats.get("runtime_topology_edges", []))
	var checked := 0
	for raw_binding in Array(stats.get("runtime_module_bindings", [])):
		if not (raw_binding is Dictionary):
			continue
		var binding: Dictionary = raw_binding
		var node := int(binding.get("side_mount_action_node", -1))
		if node < 0:
			continue
		_assert_runtime_root_flush(segments, edges, node, "unit2")
		checked += 1
	if checked < 2:
		_fail("Expected at least two Unit 2 side-mounted scythe bindings, checked %d." % checked)
		return
	fighter.queue_free()
	print("UNIT2_SCYTHE_BATTLE_ROOT_FLUSH_PROBE ok checked=%d path=%s" % [checked, ProjectSettings.globalize_path(path)])
	quit(0)
