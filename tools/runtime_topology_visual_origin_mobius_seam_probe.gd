extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")
const AssemblyBoardRenderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func _max_abs_extent(bounds: Rect2) -> float:
	var end := bounds.position + bounds.size
	return maxf(absf(bounds.position.x), maxf(absf(bounds.position.y), maxf(absf(end.x), absf(end.y))))


func _runtime_stats() -> Dictionary:
	return {
		"health": 100,
		"mass": 12.0,
		"teamedit_runtime_topology": true,
		"runtime_visual_scale": 100.0,
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"a_local": Vector2(-0.22, 0.0),
				"b_local": Vector2(0.22, 0.0),
				"radius": 0.1,
			},
			{
				"node_index": 1,
				"part_kind": "limb_muscle",
				"a_local": Vector2(0.22, 0.0),
				"b_local": Vector2(0.92, 0.0),
				"radius": 0.05,
			},
		],
	}


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"stats": _runtime_stats(),
	})
	fighter.deploy(1.0, 0.0)
	fighter.mobius_s = 25.0
	fighter.mobius_v = 0.0
	fighter.ring_pos = 1.0
	fighter.lane = 0.0
	var segment: Dictionary = fighter.runtime_world_segment_for_node(1, false)
	var combat_a: Vector2 = segment.get("a", Vector2.ZERO)
	if absf(combat_a.x - 25.22) > 0.01:
		_fail("Combat segment did not remain in unwrapped Mobius space; a=%s." % str(combat_a))
		return
	var local_polygon: PackedVector2Array = fighter._runtime_segment_polygon_local(segment)
	var bounds := _bounds(local_polygon)
	var max_abs := _max_abs_extent(bounds)
	if max_abs > 160.0:
		_fail("Runtime topology visual is still drawn a Mobius loop away from the unit; bounds=%s max_abs=%.2f." % [str(bounds), max_abs])
		return
	var delta: Vector2 = fighter.get_meta("runtime_visual_origin_delta", Vector2.ZERO)
	if absf(delta.x - 24.0) > 0.01:
		_fail("Probe did not exercise the wrapped/unwrapped seam delta; delta=%s." % str(delta))
		return
	var overlay_polygon := AssemblyBoardRenderer.runtime_segment_overlay_polygon(segment, fighter._runtime_visual_origin(), fighter.rotation, fighter._runtime_visual_scale())
	var overlay_bounds := _bounds(overlay_polygon)
	var overlay_max_abs := _max_abs_extent(overlay_bounds)
	if overlay_max_abs > 180.0:
		_fail("Runtime overlay visual origin drifted at the Mobius seam; bounds=%s max_abs=%.2f." % [str(overlay_bounds), overlay_max_abs])
		return
	print("RUNTIME_TOPOLOGY_VISUAL_ORIGIN_MOBIUS_SEAM_PROBE ok bounds=%s overlay=%s delta=%s" % [str(bounds), str(overlay_bounds), str(delta)])
	quit()
