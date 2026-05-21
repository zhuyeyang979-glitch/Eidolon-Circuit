extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_fighter():
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "REAR_100_BRAKE",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
			"mass": 10.0,
			"body_move_speed": 4.0,
			"thruster_acceleration": 8.0,
			"thruster_momentum": 40.0,
			"boost_momentum": 80.0,
			"boost_duration": 0.5,
			"thruster_cone_degrees": 180.0,
		},
	})
	fighter.deploy(0.0, 0.0)
	fighter.facing_angle = 0.0
	fighter.velocity = Vector2.RIGHT * 3.0
	return fighter


func _init() -> void:
	var inside = _make_fighter()
	inside.move_by(Vector2.LEFT.rotated(deg_to_rad(40.0)), 0.1, 24.0)
	if inside.velocity.length() >= 2.99 or float(inside.boost_flash_timer) <= 0.001:
		_fail("Input inside rear 100 degree cone should brake with boost momentum.")
		return
	var outside = _make_fighter()
	outside.move_by(Vector2.LEFT.rotated(deg_to_rad(60.0)), 0.1, 24.0)
	if float(outside.boost_flash_timer) > 0.001:
		_fail("Input outside rear 100 degree cone should not trigger brake.")
		return
	print("BRAKE_REAR_100_PROBE inside_speed=%.3f outside_speed=%.3f" % [inside.velocity.length(), outside.velocity.length()])
	quit()
