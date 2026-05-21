extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit_path(unit_name: String) -> String:
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
		if String(Dictionary(parsed).get("unit_name", "")) != unit_name:
			continue
		var modified := int(FileAccess.get_modified_time(path))
		if modified >= best_time:
			best_time = modified
			best_path = path
	return best_path


func _component_node_count(nodes: Array) -> int:
	var count := 0
	for raw_node in nodes:
		if not (raw_node is Dictionary):
			continue
		var node: Dictionary = raw_node
		if String(node.get("kind", "component")) == "component":
			count += 1
	return count


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var path := _latest_unit_path("2")
	if path == "":
		_fail("No saved unit named 2 found.")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Cannot open unit 2.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_fail("Saved unit 2 JSON invalid.")
		return
	var saved: Dictionary = main._json_restore_value(Dictionary(parsed))
	var unit_bp: Dictionary = Dictionary(saved.get("blueprint", {})).duplicate(true)
	var topology: Dictionary = Dictionary(unit_bp.get("custom_topology", {}))
	var role_key := String(saved.get("unit_role", "hero"))
	var stats: Dictionary = main._compute_unit_stats(1, role_key, -1, unit_bp)
	var nodes: Array = Array(topology.get("nodes", []))
	var segments: Array = Array(stats.get("runtime_topology_segments", []))
	var component_count := _component_node_count(nodes)
	if segments.size() != component_count:
		_fail("Runtime segment count does not match saved component node count: %d vs %d." % [segments.size(), component_count])
		return
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			_fail("Runtime segment is not a dictionary.")
			return
		var segment: Dictionary = raw_segment
		var node_index := int(segment.get("node_index", -1))
		if node_index < 0 or node_index >= nodes.size():
			_fail("Runtime segment references invalid node index %d." % node_index)
			return
	print("SAVED_UNIT_EXACT_RUNTIME_PROBE nodes=%d segments=%d" % [component_count, segments.size()])
	quit()
