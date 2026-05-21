extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const AssemblyBoardRenderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _polygons_close(a: Array, b: Array, epsilon: float = 0.002) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if Vector2(a[i]).distance_to(Vector2(b[i])) > epsilon:
			return false
	return true


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "ArtIdentity",
		"stats": {
			"health": 100,
			"mass": 20.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [
				{"node_index": 1, "part_kind": "limb_muscle", "name": "Metal Limb", "a_local": Vector2(0.0, 0.0), "b_local": Vector2(0.6, 0.0), "radius": 0.05, "material_class": "metal"},
				{"node_index": 2, "part_kind": "terminal", "name": "Blade", "a_local": Vector2(0.6, 0.0), "b_local": Vector2(0.9, 0.0), "radius": 0.06, "damage_type": "tear", "material_class": "weapon", "terminal_weapon_kind": "melee"},
			],
		},
	})
	fighter.deploy(2.0, 0.0)
	var segments: Array = fighter._runtime_topology_world_segments(true, true)
	for raw in segments:
		if not (raw is Dictionary):
			continue
		var segment: Dictionary = raw
		var runtime_polygon: Array = fighter._runtime_segment_polygon_world(segment)
		var a: Vector2 = segment.get("a", Vector2.ZERO)
		var b: Vector2 = segment.get("b", a + Vector2.RIGHT)
		var node := AssemblyBoardRenderer.segment_to_component_node(segment)
		var board_polygon := AssemblyBoardRenderer.component_polygon((a + b) * 0.5, node, b - a, float(segment.get("radius", 0.04)), a.distance_to(b), false)
		if not _polygons_close(runtime_polygon, Array(board_polygon)):
			_fail("Runtime collision polygon must use the same AssemblyBoardRenderer polygon as board art for %s." % String(segment.get("name", "")))
			return
	print("BOARD_BATTLE_ART_IDENTITY_PROBE ok segments=%d" % segments.size())
	quit()
