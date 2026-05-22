extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_p := points[0]
	var max_p := points[0]
	for p in points:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	return Rect2(min_p, max_p - min_p)


func _assert_runtime_profile(label: String, segment: Dictionary, expected_min: float, expected_max: float) -> void:
	var node := Renderer.segment_to_component_node(segment)
	var a := Vector2(segment.get("a", Vector2.ZERO))
	var b := Vector2(segment.get("b", Vector2.RIGHT))
	var length := a.distance_to(b)
	var tiny := Renderer.component_polygon((a + b) * 0.5, node, b - a, 0.01, length, false)
	var huge := Renderer.component_polygon((a + b) * 0.5, node, b - a, 10.0, length, false)
	var ratio := _bounds(tiny).size.y / maxf(0.001, length)
	var huge_ratio := _bounds(huge).size.y / maxf(0.001, length)
	if ratio < expected_min or ratio > expected_max:
		_fail("%s runtime profile ratio %.3f is outside expected thumbnail-style range %.3f..%.3f" % [label, ratio, expected_min, expected_max])
	if absf(ratio - huge_ratio) > 0.001:
		_fail("%s runtime collider still depends on raw segment radius: %.3f vs %.3f" % [label, ratio, huge_ratio])


func _init() -> void:
	var renderer_source := FileAccess.get_file_as_string("res://scripts/assembly_board_renderer.gd")
	var fighter_source := FileAccess.get_file_as_string("res://scripts/fighter.gd")
	if not renderer_source.contains("component_display_radius"):
		_fail("AssemblyBoardRenderer is missing component_display_radius.")
	if not renderer_source.contains("draw_component(canvas, center, node, draw_color, axis, radius_px, 0.0, visual_length, true)"):
		_fail("Runtime segment drawing does not request the thumbnail-style display profile.")
	if not fighter_source.contains("AssemblyBoardRenderer.component_polygon"):
		_fail("Fighter runtime collision no longer uses AssemblyBoardRenderer.component_polygon.")
	_assert_runtime_profile("torso", {"part_kind": "torso", "a": Vector2(0, 0), "b": Vector2(1, 0), "joint_ports": 4}, 0.45, 0.49)
	_assert_runtime_profile("limb", {"part_kind": "limb_muscle", "a": Vector2(0, 0), "b": Vector2(1, 0)}, 0.10, 0.12)
	_assert_runtime_profile("terminal", {"part_kind": "terminal", "a": Vector2(0, 0), "b": Vector2(1, 0), "damage_type": "blunt"}, 0.22, 0.24)
	print("BATTLE_PREVIEW_ART_IDENTITY_PROBE ok")
	quit(0)
