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
		"runtime_visual_scale": 110.0,
		"runtime_topology_segments": [
			{
				"node_index": 0,
				"part_kind": "torso",
				"name": "SEAM CORE",
				"a_local": Vector2(-0.24, 0.0),
				"b_local": Vector2(0.24, 0.0),
				"radius": 0.11,
				"material_class": "torso",
			},
			{
				"node_index": 1,
				"part_kind": "limb_muscle",
				"name": "SEAM ARM",
				"a_local": Vector2(0.24, 0.0),
				"b_local": Vector2(0.84, 0.0),
				"radius": 0.045,
				"material_class": "body",
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
	fighter.current_state = "armor"
	fighter.state_timer = 0.5
	var segments: Array = fighter._runtime_status_curve_overlay_segments()
	if segments.size() != 2:
		_fail("Status overlay did not use runtime topology segments at seam; segments=%d." % segments.size())
		return
	for raw_segment in segments:
		if not (raw_segment is Dictionary):
			continue
		var segment: Dictionary = raw_segment
		var fixed_polygon := AssemblyBoardRenderer.runtime_segment_overlay_polygon(segment, fighter._runtime_visual_origin(), fighter.rotation, fighter._runtime_visual_scale())
		var fixed_bounds := _bounds(fixed_polygon)
		var fixed_extent := _max_abs_extent(fixed_bounds)
		if fixed_extent > 180.0:
			_fail("Status overlay polygon is still drawn away from the unit at seam; bounds=%s extent=%.2f." % [str(fixed_bounds), fixed_extent])
			return
		var wrapped_polygon := AssemblyBoardRenderer.runtime_segment_overlay_polygon(segment, Vector2(fighter.ring_pos, fighter.lane), fighter.rotation, fighter._runtime_visual_scale())
		var wrapped_extent := _max_abs_extent(_bounds(wrapped_polygon))
		if wrapped_extent < 1200.0:
			_fail("Probe did not prove the old wrapped-origin failure mode; wrapped_extent=%.2f." % wrapped_extent)
			return
	var source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	if source.find("draw_runtime_segment_status_overlay(self, Dictionary(raw_segment), Vector2(ring_pos, lane)") >= 0:
		_fail("Fighter status overlay still passes wrapped ring_pos/lane to the renderer.")
		return
	print("RUNTIME_STATUS_OVERLAY_MOBIUS_SEAM_PROBE ok segments=%d delta=%s" % [segments.size(), str(fighter.get_meta("runtime_visual_origin_delta", Vector2.ZERO))])
	quit()
