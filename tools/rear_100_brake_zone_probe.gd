extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit():
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "Rear100Probe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"body_move_speed": 3.0,
			"thruster_acceleration": 40.0,
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
	var rear_unit = _make_unit()
	rear_unit.velocity = Vector2.RIGHT * 1.0
	rear_unit.move_by(Vector2.LEFT, 0.2, 24.0)
	if rear_unit.velocity.length() > 0.001:
		_fail("Pure rear input should brake to zero.")
		return
	if rear_unit.boost(Vector2.LEFT, 24.0):
		_fail("Pure rear input must not boost.")
		return

	var side_back_unit = _make_unit()
	var side_back := Vector2(-0.45, 0.89).normalized()
	side_back_unit.move_by(side_back, 0.12, 24.0)
	if side_back_unit.velocity.length() <= 0.001:
		_fail("Side/back-side input outside rear 100 degrees should drive.")
		return
	if not side_back_unit.boost(side_back, 24.0):
		_fail("Side/back-side input outside rear 100 degrees should boost.")
		return
	print("REAR_100_BRAKE_ZONE_PROBE ok side_back_speed=%.3f" % side_back_unit.velocity.length())
	quit()
