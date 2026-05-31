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
			"thruster_drive_demand": 60.0,
			"thruster_effective_drive_demand": 60.0,
			"thruster_boost_extra_demand": 60.0,
			"thruster_boost_peak_demand": 120.0,
			"thruster_effective_boost_peak_demand": 120.0,
			"engine_drive_chain_ratio": 1.0,
			"engine_boost_chain_ratio": 1.0,
			"move_momentum": 60.0,
			"body_move_speed": 3.0,
			"move_speed": 3.0,
			"thruster_acceleration": 40.0,
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
	var rear_unit = _make_unit()
	rear_unit.velocity = Vector2.RIGHT * 1.0
	rear_unit.move_by(Vector2.LEFT, 0.2, 24.0)
	if rear_unit.velocity.length() > 0.001:
		_fail("Pure rear input should brake to zero before reverse movement.")
		return
	if rear_unit.boost(Vector2.LEFT, 24.0):
		_fail("Pure rear input should never trigger boost.")
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
