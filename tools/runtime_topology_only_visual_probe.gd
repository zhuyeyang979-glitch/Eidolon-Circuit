extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_torso_index(main) -> int:
	for i in range(main._catalog_for("hero", "muscle").size()):
		if main._component_is_torso(main._selected_component("hero", "muscle", i)):
			return i
	return -1


func _first_limb_index(main) -> int:
	for i in range(main._catalog_for("hero", "limb_muscle").size()):
		var part: Dictionary = main._selected_component("hero", "limb_muscle", i)
		if not main._part_counts_as_terminal_weapon(part, "limb_muscle"):
			return i
	return 0


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var unit_bp: Dictionary = main._make_editor_blank_blueprint("hero")
	unit_bp["role"] = "hero"
	unit_bp["blank_canvas"] = false
	var nodes: Array = []
	var edges: Array = []
	var torso := main._append_component_root_node(nodes, "CORE", Vector2(0.5, 0.5), _first_torso_index(main))
	main._append_directed_component_node("hero", unit_bp, nodes, edges, torso, "LINK", "limb_muscle", _first_limb_index(main), Vector2.RIGHT, [0])
	unit_bp["custom_topology"] = {"nodes": nodes, "edges": edges, "edge_snap_version": MainScene.TOPOLOGY_SNAP_VERSION}
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Runtime Visual", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(4.0, 0.0)
	for legacy_name in ["Shell", "TopologyLine", "MuscleA", "MuscleB", "JointA", "JointB", "SpecialCore", "CoreProceduralArt"]:
		if fighter.find_child(legacy_name, true, false) != null:
			_fail("Legacy visual node still exists on a TeamEdit runtime unit: %s." % legacy_name)
	for legacy_name in ["TorsoMuscleCollider", "MuscleCollider*", "ConnectionGuide*", "WeaponFace*", "TerminalHandleRing*", "SocketHingeRing*"]:
		if fighter.find_child(legacy_name, true, false) != null:
			_fail("Legacy child visual node still exists on a TeamEdit runtime unit: %s." % legacy_name)
	for raw_line in fighter.barrier_tile_lines:
		var line: Line2D = raw_line
		if line.visible:
			_fail("Barrier-only tile visual line is visible on a TeamEdit runtime unit.")
	var expected := Array(stats.get("runtime_topology_segments", [])).size()
	if fighter.find_child("RuntimePartHull*", true, false) != null or fighter.find_child("RuntimeTorsoHull*", true, false) != null:
		_fail("TeamEdit runtime unit still creates legacy RuntimePartHull/RuntimeTorsoHull children.")
	if expected <= 0 or not fighter._has_runtime_topology():
		_fail("Runtime topology segments are missing.")
	var direct_draw_polygons := 0
	for raw_segment in fighter._runtime_topology_world_segments(true, false):
		if raw_segment is Dictionary and fighter._runtime_segment_polygon_local(Dictionary(raw_segment)).size() >= 3:
			direct_draw_polygons += 1
	if direct_draw_polygons != expected:
		_fail("Direct board-draw polygon count mismatch: %d vs %d." % [direct_draw_polygons, expected])
	print("RUNTIME_TOPOLOGY_ONLY_VISUAL_PROBE direct_draw_polygons=%d" % direct_draw_polygons)
	quit()
