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
			"body_move_speed": 2.0,
			"thruster_acceleration": 24.0,
			"boost_momentum": 60.0,
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
		_fail("Reverse input should brake the unit to a stop.")
		return
	if bool(unit.brake_reverse_requires_repress) != true:
		_fail("Brake reverse should require release/repress after stopping.")
		return
	unit.move_by(Vector2.LEFT, 0.1, 24.0)
	if unit.velocity.x < -0.001:
		_fail("Holding the same reverse input should not immediately become reverse movement.")
		return
	unit.note_movement_input_released()
	unit.move_by(Vector2.LEFT, 0.1, 24.0)
	if unit.velocity.x >= -0.001:
		_fail("Re-pressing the same direction after braking should allow normal reverse movement.")
		return
	print("BRAKE_REVERSE_AFTER_STOP_PROBE ok velocity=%.3f" % unit.velocity.x)
	quit()
