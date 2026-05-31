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
			"thruster_drive_demand": 40.0,
			"thruster_effective_drive_demand": 40.0,
			"thruster_boost_extra_demand": 80.0,
			"thruster_boost_peak_demand": 120.0,
			"thruster_effective_boost_peak_demand": 120.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 40.0,
			"body_move_speed": 4.0,
			"move_speed": 4.0,
			"thruster_acceleration": 8.0,
			"thruster_momentum": 40.0,
			"boost_momentum": 80.0,
			"boost_total_momentum": 120.0,
			"boost_speed": 12.0,
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
	if inside.velocity.x >= 3.0:
		_fail("Input inside rear cone should brake current forward movement.")
		return
	var outside = _make_fighter()
	outside.move_by(Vector2.DOWN, 0.1, 24.0)
	if absf(outside.velocity.y) <= 0.001:
		_fail("Side input outside the rear cone should directly steer ordinary movement.")
		return
	print("BRAKE_REAR_100_PROBE inside_speed=%.3f outside_speed=%.3f" % [inside.velocity.length(), outside.velocity.length()])
	quit()
