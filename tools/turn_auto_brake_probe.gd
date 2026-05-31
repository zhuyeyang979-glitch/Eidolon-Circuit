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
		"unit_name": "TURN_BRAKE",
		"stats": {
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso", "node_index": 0, "a_local": Vector2(-0.2, 0.0), "b_local": Vector2(0.2, 0.0), "radius": 0.08}],
			"mass": 10.0,
			"thruster_drive_demand": 120.0,
			"thruster_effective_drive_demand": 120.0,
			"thruster_boost_extra_demand": 120.0,
			"thruster_boost_peak_demand": 240.0,
			"thruster_effective_boost_peak_demand": 240.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 120.0,
			"turn_speed": 5.0,
			"turn_command_rate": 5.0,
			"turn_acceleration": 12.0,
			"turn_damping": 0.0,
			"boost_momentum": 120.0,
			"boost_total_momentum": 240.0,
			"boost_speed": 24.0,
			"boost_duration": 0.3,
		},
	})
	fighter.deploy(0.0, 0.0)
	return fighter


func _init() -> void:
	var fighter = _make_fighter()
	fighter.request_turn(1, 0.1)
	fighter.tick(0.1, 24.0)
	if absf(fighter.angular_velocity) <= 0.001:
		_fail("Turn input should create angular velocity.")
		return
	var moving_angle: float = fighter.facing_angle
	var moving_velocity: float = absf(fighter.angular_velocity)
	fighter.set_turn_input_active(false)
	fighter.tick(0.2, 24.0)
	if absf(fighter.angular_velocity) >= moving_velocity:
		_fail("Released turn key should brake angular velocity.")
		return
	if absf(fighter.facing_angle - moving_angle) > moving_velocity * 0.4:
		_fail("Turn brake should not keep freely spinning after release.")
		return
	fighter.tick(1.0, 24.0)
	if absf(fighter.angular_velocity) > 0.002:
		_fail("Turn brake should settle angular velocity to zero.")
		return
	print("TURN_AUTO_BRAKE_PROBE residual=%.4f" % fighter.angular_velocity)
	quit()
