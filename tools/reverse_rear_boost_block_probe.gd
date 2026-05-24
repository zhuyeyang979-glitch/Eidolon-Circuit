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
		"unit_name": "ReverseRearBoostBlock",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"move_momentum": 60.0,
			"move_speed": 3.0,
			"thruster_acceleration": 40.0,
			"thruster_boost_extra_demand": 60.0,
			"boost_momentum": 60.0,
			"boost_total_momentum": 120.0,
			"boost_speed": 12.0,
			"boost_duration": 0.3,
			"boost_angle_degrees": 360.0,
			"movement_profile": "omni",
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.set_facing_immediate(1)
	return unit


func _init() -> void:
	var rear = _make_unit()
	if rear.boost(Vector2.LEFT, 24.0):
		_fail("Rear/reverse direction must not boost even with 360-degree omni boost angle.")
		return
	if rear.boost_drive_timer > 0.0 or rear.boost_drive_velocity_remaining.length() > 0.001:
		_fail("Rear/reverse boost attempt armed boost state.")
		return
	var side = _make_unit()
	if not side.boost(Vector2.DOWN, 24.0):
		_fail("Side direction inside a 360-degree thruster boost range should still boost.")
		return
	print("REVERSE_REAR_BOOST_BLOCK_PROBE ok")
	quit()
