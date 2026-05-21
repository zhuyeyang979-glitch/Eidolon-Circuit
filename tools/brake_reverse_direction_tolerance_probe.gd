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
	unit.note_movement_input_released()
	unit.move_by(Vector2(-1.0, 0.22).normalized(), 0.1, 24.0)
	if unit.velocity.x >= -0.001:
		_fail("Small angular drift from the recorded reverse direction should still allow reverse.")
		return
	var unit2 = _make_runtime_fighter()
	unit2.velocity = Vector2.RIGHT * 1.0
	unit2.move_by(Vector2.LEFT, 0.2, 24.0)
	unit2.note_movement_input_released()
	unit2.move_by(Vector2.DOWN, 0.1, 24.0)
	if unit2.velocity.x < -0.001:
		_fail("Different direction should not trigger backward reverse movement.")
		return
	print("BRAKE_REVERSE_DIRECTION_TOLERANCE_PROBE ok")
	quit()
