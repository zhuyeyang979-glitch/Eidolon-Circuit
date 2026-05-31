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
		"unit_name": "BrakeReverseToleranceProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"thruster_drive_demand": 60.0,
			"thruster_effective_drive_demand": 60.0,
			"thruster_boost_extra_demand": 60.0,
			"thruster_boost_peak_demand": 120.0,
			"thruster_effective_boost_peak_demand": 120.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 60.0,
			"body_move_speed": 2.0,
			"move_speed": 2.0,
			"thruster_acceleration": 24.0,
			"boost_momentum": 60.0,
			"boost_total_momentum": 120.0,
			"boost_speed": 12.0,
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
	unit.velocity = Vector2.RIGHT * 1.0
	unit.move_by(Vector2.LEFT, 0.2, 24.0)
	unit.note_movement_input_released()
	unit.move_by(Vector2(-1.0, 0.22).normalized(), 0.1, 24.0)
	if unit.velocity.x >= -0.001:
		_fail("Small angular drift should still allow ordinary reverse movement.")
		return
	var unit2 = _make_runtime_fighter()
	unit2.velocity = Vector2.RIGHT * 1.0
	unit2.move_by(Vector2.LEFT, 0.2, 24.0)
	unit2.note_movement_input_released()
	unit2.move_by(Vector2.DOWN, 0.1, 24.0)
	if unit2.velocity.y <= 0.001:
		_fail("Different screen direction should directly steer ordinary movement in that direction.")
		return
	print("BRAKE_REVERSE_DIRECTION_TOLERANCE_PROBE ok")
	quit()
