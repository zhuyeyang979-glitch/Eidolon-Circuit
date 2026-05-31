extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_runtime_fighter():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "BrakeProbe",
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
	return unit


func _init() -> void:
	var unit = _make_runtime_fighter()
	unit.velocity = Vector2.RIGHT * 2.0
	unit.move_by(Vector2.LEFT, 0.1, 24.0)
	if unit.velocity.x >= 2.0:
		_fail("Reverse ordinary movement did not steer velocity toward reverse.")
		return
	if String(unit.get_meta("last_move_command_mode", "")) != "brake":
		_fail("Reverse ordinary movement should enter brake command mode before reverse drive.")
		return
	print("BRAKE_UNUSABLE_DIRECTION_PROBE ok velocity=%.3f" % unit.velocity.length())
	quit()
