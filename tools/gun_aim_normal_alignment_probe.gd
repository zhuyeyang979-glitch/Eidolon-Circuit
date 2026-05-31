extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _axis(segment: Dictionary) -> Vector2:
	var a: Vector2 = segment.get("a", Vector2.ZERO)
	var b: Vector2 = segment.get("b", Vector2.ZERO)
	var d := b - a
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


func _init() -> void:
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "AIM",
		"stats": {
			"teamedit_runtime_topology": true,
			"mass": 12.0,
			"health": 100,
			"max_health": 100,
			"runtime_topology_segments": [{
				"node_index": 2,
				"part_kind": "terminal",
				"terminal_weapon_kind": "ranged",
				"projectile": true,
				"a_local": Vector2.ZERO,
				"b_local": Vector2.RIGHT,
				"axis_local": Vector2.RIGHT,
				"radius": 0.04,
				"polygon_local": [Vector2(0.0, -0.04), Vector2(1.0, -0.04), Vector2(1.0, 0.04), Vector2(0.0, 0.04)],
			}],
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.set_aim_pose(2, Vector2.UP, 0.5)
	var found := false
	for raw_segment in fighter._runtime_topology_world_segments(false, true):
		var segment: Dictionary = raw_segment
		if int(segment.get("node_index", -1)) != 2:
			continue
		found = true
		var axis := _axis(segment)
		if absf(axis.angle_to(Vector2.UP)) > deg_to_rad(1.0):
			_fail("Gun segment normal should align with aim line. axis=%s" % [axis])
	if not found:
		_fail("Gun segment was not produced.")
	print("GUN_AIM_NORMAL_ALIGNMENT_PROBE ok")
	quit()
