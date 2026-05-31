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
		"unit_name": "BrakeReverseProbe",
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
	if unit.velocity.length() > 0.001:
		_fail("Reverse input should first brake to stop, got velocity %s." % unit.velocity)
		return
	if not bool(unit.brake_reverse_requires_repress):
		_fail("Brake-to-stop should require release/repress before reverse drive.")
		return
	unit.move_by(Vector2.LEFT, 0.1, 24.0)
	if unit.velocity.x < -0.001:
		_fail("Holding reverse should not enter reverse movement before release/repress.")
		return
	unit.note_movement_input_released()
	unit.move_by(Vector2.LEFT, 0.1, 24.0)
	if unit.velocity.x >= -0.001:
		_fail("Re-pressing reverse should allow normal reverse movement.")
		return
	print("BRAKE_REVERSE_AFTER_STOP_PROBE ok direct_reverse_velocity=%.3f" % unit.velocity.x)
	quit()
