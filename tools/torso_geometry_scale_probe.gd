extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var torso_index := _first_torso(main)
	if torso_index < 0:
		_fail("No torso part found.")
		return
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	var nodes: Array = []
	var edges: Array = []
	main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), torso_index)
	unit_bp["blank_canvas"] = false
	unit_bp["role"] = "hero"
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var part: Dictionary = main._selected_component("hero", "muscle", torso_index)
	var base_length := maxf(0.08, float(part.get("length", 0.32)))
	var base_radius := maxf(0.018, float(part.get("radius", 0.09)))
	var segments: Array = main._runtime_topology_segments_for_blueprint("hero", unit_bp)
	if segments.is_empty():
		_fail("Runtime topology did not produce torso segment.")
		return
	var torso_segment: Dictionary = segments[0]
	var seg_len: float = (torso_segment.get("b_local", Vector2.ZERO) - torso_segment.get("a_local", Vector2.ZERO)).length()
	var seg_radius := float(torso_segment.get("radius", 0.0))
	if absf(seg_len - base_length * 2.0) > 0.001:
		_fail("Runtime torso length not scaled 2x: %.4f vs %.4f." % [seg_len, base_length * 2.0])
		return
	if absf(seg_radius - base_radius * 2.0) > 0.001:
		_fail("Runtime torso radius not scaled 2x: %.4f vs %.4f." % [seg_radius, base_radius * 2.0])
		return
	var points := PartArt.torso_saddle_local_points(base_length, base_radius * 1.2, base_radius * 2.4)
	var min_x := 999.0
	var max_x := -999.0
	for point in points:
		var p: Vector2 = point
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
	if absf((max_x - min_x) - base_length * 2.0) > 0.001:
		_fail("PartArt torso outline not scaled 2x.")
		return
	print("TORSO_GEOMETRY_SCALE_PROBE length=%.3f radius=%.3f" % [seg_len, seg_radius])
	quit()
