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
	var catalog: Array = main._catalog_for("hero", "limb_muscle")
	return 0 if catalog.size() > 0 else -1


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
	var limb := main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "HANDLE LIMB", "limb_muscle", _first_limb(main), Vector2.RIGHT)
	var scythe := main._append_directed_component_node("hero", unit_bp, nodes, edges, limb, "DRAGGED SCYTHE", "muscle", _scythe_index(main), Vector2.RIGHT)
	var dragged: Dictionary = Dictionary(nodes[scythe]).duplicate(true)
	dragged["pos"] = Vector2(0.78, 0.74)
	dragged["axis"] = Vector2.DOWN
	dragged["visual_mount_side"] = "right"
	nodes[scythe] = dragged
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	unit_bp["blank_canvas"] = false
	var enriched := main._editor_fast_enriched_board_node("hero", unit_bp, nodes, edges, scythe)
	var parent_axis: Vector2 = main._topology_endpoint_axis_for_node(limb, nodes, edges).normalized()
	var mount_axis: Vector2 = enriched.get("mount_parent_axis_local", Vector2.ZERO)
	if mount_axis.length() < 0.001 or absf(mount_axis.normalized().dot(parent_axis)) < 0.99:
		_fail("Dragged scythe did not use parent limb axis: mount=%s parent=%s" % [mount_axis, parent_axis])
		return
	var poly_a := Renderer.terminal_polygon(Vector2.ZERO, enriched, Vector2.RIGHT, 16.0, 100.0)
	var poly_b := Renderer.terminal_polygon(Vector2.ZERO, enriched, Vector2.DOWN, 16.0, 100.0)
	if poly_a.size() != poly_b.size():
		_fail("Dragged scythe polygon changed point count when terminal axis changed.")
		return
	for i in range(poly_a.size()):
		if Vector2(poly_a[i]).distance_to(Vector2(poly_b[i])) > 0.001:
			_fail("Dragged scythe visual should ignore terminal self-axis and use parent axis at point %d." % i)
			return
	print("SCYTHE_DRAGGED_TERMINAL_USES_PARENT_AXIS_PROBE ok node=%d" % scythe)
	quit()
