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
		"unit_name": "ReverseBoostProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"body_move_speed": 2.0,
			"thruster_acceleration": 24.0,
			"boost_momentum": 80.0,
			"boost_duration": 0.3,
			"movement_profile": "car",
			"boost_angle_degrees": 120.0,
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
	unit.move_by(Vector2.LEFT, 0.1, 24.0)
	var reverse_velocity: float = unit.velocity.x
	var boosted := unit.boost(Vector2.LEFT, 24.0)
	if boosted:
		_fail("Reverse direction should never trigger boost.")
		return
	if unit.boost_drive_timer > 0.0 or unit.boost_drive_velocity_remaining.length() > 0.001:
		_fail("Reverse direction should not arm boost drive state.")
		return
	if unit.velocity.x < reverse_velocity - 0.001:
		_fail("Reverse boost attempt should not add extra backward velocity.")
		return
	print("REVERSE_CANNOT_BOOST_PROBE ok")
	quit()
