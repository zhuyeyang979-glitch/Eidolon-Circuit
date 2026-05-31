extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "VelocityClampProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"body_move_speed": 3.0,
			"thruster_acceleration": 10.0,
			"boost_momentum": 60.0,
			"boost_duration": 0.3,
			"speedometer_max_speed": 3.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	unit.velocity = Vector2.RIGHT * 12.0
	unit.tick(0.016, 24.0)
	if unit.velocity.length() > 3.01:
		_fail("Velocity should be clamped to speedometer max, got %.3f" % unit.velocity.length())
		return
	print("VELOCITY_CLAMPED_TO_GAUGE_PROBE ok speed=%.3f" % unit.velocity.length())
	quit()
