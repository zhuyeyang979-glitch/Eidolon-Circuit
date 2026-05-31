extends SceneTree

const Renderer := preload("res://scripts/assembly_board_renderer.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _node(side: String, parent_axis: Vector2) -> Dictionary:
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
		"orientation_category": "orthogonal_side_mount",
		"orientation_basis": "parent_normal",
		"visual_mount_side": side,
		"mount_parent_axis_local": parent_axis,
	}


func _basis_coords(points: PackedVector2Array, forward: Vector2) -> Array:
	var f := forward.normalized()
	var r := Vector2(-f.y, f.x)
	var result: Array = []
	for point in points:
		var p: Vector2 = point
		result.append(Vector2(p.dot(f), p.dot(r)))
	return result


func _init() -> void:
	var center := Vector2.ZERO
	var terminal_axis := Vector2.RIGHT
	var parent_axis := Vector2.UP
	var radius := 16.0
	var length := 100.0
	var right_poly := Renderer.terminal_polygon(center, _node("right", parent_axis), terminal_axis, radius, length)
	var left_poly := Renderer.terminal_polygon(center, _node("left", parent_axis), terminal_axis, radius, length)
	if right_poly.size() != left_poly.size() or right_poly.size() < 10:
		_fail("Left/right side-mount scythe polygons should have matching readable point counts.")
		return
	var right_basis := _basis_coords(right_poly, parent_axis)
	var left_basis := _basis_coords(left_poly, parent_axis)
	for i in range(right_basis.size()):
		var rp: Vector2 = right_basis[i]
		var lp: Vector2 = left_basis[i]
		if absf(rp.x - lp.x) > 0.001 or absf(rp.y + lp.y) > 0.001:
			_fail("Scythe side mount should mirror around parent axis normal at point %d: right=%s left=%s" % [i, rp, lp])
			return
	var own_axis_mirror_match := true
	for i in range(right_poly.size()):
		var rp := Vector2(right_poly[i])
		var lp := Vector2(left_poly[i])
		if absf(rp.x - lp.x) > 0.001 or absf(rp.y + lp.y) > 0.001:
			own_axis_mirror_match = false
			break
	if own_axis_mirror_match:
		_fail("Scythe side mount incorrectly mirrored around its own terminal axis.")
		return
	print("SCYTHE_PARENT_NORMAL_MOUNT_POLYGON_PROBE ok points=%d" % right_poly.size())
	quit()
