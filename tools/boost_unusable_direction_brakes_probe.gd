extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BoostBrakeProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"thruster_drive_demand": 30.0,
			"thruster_effective_drive_demand": 30.0,
			"thruster_boost_extra_demand": 30.0,
			"thruster_boost_peak_demand": 60.0,
			"thruster_effective_boost_peak_demand": 60.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 30.0,
			"body_move_speed": 3.0,
			"move_speed": 3.0,
			"thruster_acceleration": 8.0,
			"boost_momentum": 30.0,
			"boost_total_momentum": 60.0,
			"boost_speed": 6.0,
			"boost_duration": 0.3,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.set_facing_immediate(1)
	unit.velocity = Vector2.RIGHT * 2.0
	var boosted := unit.boost(Vector2.LEFT, 24.0)
	if boosted:
		_fail("Reverse boost should not start a boost drive.")
		return
	if unit.velocity.length() > 0.001:
		_fail("Reverse boost should spend boost momentum to brake to zero in this setup.")
		return
	var reason := String(unit.get_meta("last_velocity_brake_reason", ""))
	if reason not in ["unusable_boost_angle", "reverse_brake"]:
		_fail("Brake reason should be unusable_boost_angle or reverse_brake, got %s." % reason)
		return
	print("BOOST_UNUSABLE_DIRECTION_BRAKES_PROBE ok")
	quit()
