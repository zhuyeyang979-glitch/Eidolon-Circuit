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


func _assert_ratio(label: String, node: Dictionary, expected_min: float, expected_max: float) -> void:
	var length := 1.0
	var raw_tiny_radius := 0.01
	var raw_huge_radius := 10.0
	var poly_tiny := Renderer.component_polygon(Vector2.ZERO, node, Vector2.RIGHT, raw_tiny_radius, length, false)
	var poly_huge := Renderer.component_polygon(Vector2.ZERO, node, Vector2.RIGHT, raw_huge_radius, length, false)
	var ratio := _bounds(poly_tiny).size.y / length
	var huge_ratio := _bounds(poly_huge).size.y / length
	if ratio < expected_min or ratio > expected_max:
		_fail("%s board profile ratio %.3f is outside expected thumbnail-style range %.3f..%.3f" % [label, ratio, expected_min, expected_max])
	if absf(ratio - huge_ratio) > 0.001:
		_fail("%s board profile still depends on raw physical radius: %.3f vs %.3f" % [label, ratio, huge_ratio])


func _init() -> void:
	_assert_ratio("torso", {"slot": "muscle", "is_torso": true, "shape": "torso", "connection_ends": 4}, 0.45, 0.49)
	_assert_ratio("limb", {"slot": "limb_muscle", "shape": "limb", "connection_ends": 2}, 0.10, 0.12)
	_assert_ratio("terminal", {"slot": "muscle", "terminal_weapon": true, "connection_ends": 1, "damage_type": "blunt"}, 0.22, 0.24)
	_assert_ratio("barrier", {"slot": "barrier_tile", "is_barrier_tile": true, "shape": "barrier"}, 0.15, 0.18)
	print("PART_PREVIEW_BOARD_ART_IDENTITY_PROBE ok")
	quit(0)
