extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _node(side: String) -> Dictionary:
	return {
		"slot": "muscle",
		"terminal_weapon": true,
		"terminal_weapon_kind": "melee",
		"weapon_family": "scythe",
		"shape": "scythe",
		"source_shape": "scythe",
		"damage_type": "tear",
		"material_class": "weapon",
		"connection_ends": 1,
		"component_name": "SCYTHE",
		"asymmetric_terminal": true,
		"visual_handedness": side,
	}


func _init() -> void:
	var center := Vector2.ZERO
	var axis := Vector2.RIGHT
	var radius := 16.0
	var length := 100.0
	var right_poly := Renderer.terminal_polygon(center, _node("right"), axis, radius, length)
	var left_poly := Renderer.terminal_polygon(center, _node("left"), axis, radius, length)
	if right_poly.size() != left_poly.size() or right_poly.size() < 10:
		_fail("Left/right scythe polygons should have the same readable point count.")
		return
	for i in range(right_poly.size()):
		var rp := Vector2(right_poly[i])
		var lp := Vector2(left_poly[i])
		if absf(rp.x - lp.x) > 0.001 or absf(rp.y + lp.y) > 0.001:
			_fail("Scythe handedness should mirror across local forward axis at point %d: right=%s left=%s" % [i, rp, lp])
			return
	var default_poly := Renderer.terminal_polygon(center, _node(""), axis, radius, length)
	for i in range(right_poly.size()):
		if Vector2(default_poly[i]).distance_to(Vector2(right_poly[i])) > 0.001:
			_fail("Default scythe handedness should match right.")
			return
	print("SCYTHE_HANDEDNESS_POLYGON_PROBE ok points=%d" % right_poly.size())
	quit()
