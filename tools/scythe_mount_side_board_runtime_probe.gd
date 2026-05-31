extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb(main: Node) -> int:
	return 0 if main._catalog_for("hero", "limb_muscle").size() > 0 else -1


func _scythe_index(main: Node) -> int:
	var catalog: Array = main._catalog_for("hero", "muscle")
	for i in range(catalog.size()):
		var part: Dictionary = main._selected_component("hero", "muscle", i)
		if main._blade_weapon_family_for_part(part) == "scythe" and main._part_counts_as_terminal_weapon(part, "muscle"):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor(true)
	main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.42, 0.5), _first_torso(main))
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "HANDLE", "limb_muscle", _first_limb(main), Vector2.RIGHT)
	var scythe := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "LEFT SIDE SCYTHE", "muscle", _scythe_index(main), Vector2.RIGHT)
	var scythe_node: Dictionary = Dictionary(nodes[scythe]).duplicate(true)
	scythe_node["visual_mount_side"] = "left"
	nodes[scythe] = scythe_node
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	main.editor_working_role_key = "hero"
	main.editor_working_blueprint = unit_bp
	main.editor_topology_node_index = scythe
	main._refresh_editor_visual_views()
	var enriched := main._editor_fast_enriched_board_node("hero", unit_bp, nodes, edges, scythe)
	if String(enriched.get("visual_mount_side", "")) != "left":
		_fail("Board-enriched scythe node lost visual_mount_side=left.")
		return
	if String(enriched.get("orientation_category", "")) != "orthogonal_side_mount":
		_fail("Board-enriched scythe node lost orientation_category.")
		return
	var expected_axis: Vector2 = main._topology_endpoint_axis_for_node(limb, nodes, edges).normalized()
	var board_axis: Vector2 = enriched.get("mount_parent_axis_local", Vector2.ZERO)
	if board_axis.length() < 0.001 or absf(board_axis.normalized().dot(expected_axis)) < 0.99:
		_fail("Board scythe mount parent axis is not the parent limb axis.")
		return
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var found_runtime := false
	for raw_segment in Array(stats.get("runtime_topology_segments", [])):
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		if int(segment.get("node_index", -1)) != scythe:
			continue
		found_runtime = true
		if String(segment.get("visual_mount_side", "")) != "left":
			_fail("Runtime segment lost visual_mount_side=left.")
			return
		var runtime_axis: Vector2 = segment.get("mount_parent_axis_local", Vector2.ZERO)
		if runtime_axis.length() < 0.001 or absf(runtime_axis.normalized().dot(expected_axis)) < 0.99:
			_fail("Runtime segment lost parent mount axis.")
			return
		var component_node := Renderer.segment_to_component_node(segment)
		if String(component_node.get("visual_mount_side", "")) != "left":
			_fail("Renderer runtime component node lost visual_mount_side=left.")
			return
	if not found_runtime:
		_fail("Scythe runtime segment was not produced.")
		return
	print("SCYTHE_MOUNT_SIDE_BOARD_RUNTIME_PROBE ok node=%d" % scythe)
	quit()
