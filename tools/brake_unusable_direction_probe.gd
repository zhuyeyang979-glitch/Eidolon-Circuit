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
			"body_move_speed": 3.0,
			"thruster_acceleration": 8.0,
			"boost_momentum": 30.0,
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
		_fail("Unusable reverse movement angle did not brake velocity.")
		return
	if unit.velocity.x < -0.001:
		_fail("Reverse movement produced backward velocity instead of braking.")
		return
	if String(unit.get_meta("last_velocity_brake_reason", "")) != "unusable_move_angle":
		_fail("Brake reason should be unusable_move_angle.")
		return
	print("BRAKE_UNUSABLE_DIRECTION_PROBE ok velocity=%.3f" % unit.velocity.length())
	quit()
